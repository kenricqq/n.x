import { afterEach, describe, expect, test } from 'bun:test'
import { chmod, mkdtemp, rm, writeFile } from 'node:fs/promises'
import { createServer } from 'node:net'
import { tmpdir } from 'node:os'
import { join } from 'node:path'

type RunningShim = {
	origin: string
	stop: () => Promise<void>
}

const running: RunningShim[] = []
const projectDir = import.meta.dir

const sleep = (ms: number): Promise<void> => new Promise((resolve) => setTimeout(resolve, ms))

async function getFreePort(): Promise<number> {
	return new Promise((resolve, reject) => {
		const server = createServer()
		server.once('error', reject)
		server.listen(0, '127.0.0.1', () => {
			const address = server.address()
			server.close(() => {
				if (address && typeof address === 'object') resolve(address.port)
				else reject(new Error('failed to allocate port'))
			})
		})
	})
}

async function startShim(delaySeconds = 0.05): Promise<RunningShim> {
	const tmp = await mkdtemp(join(tmpdir(), 'pi-shim-test-'))
	const fakePi = join(tmp, 'pi')
	await writeFile(
		fakePi,
		`#!/usr/bin/env bash
json=0
while [ "$#" -gt 0 ]; do
  if [ "$1" = "--mode" ] && [ "\${2:-}" = "json" ]; then json=1; fi
  shift
done
if [ "$json" = 1 ]; then
  printf '%s\n' '{"type":"message_update","assistantMessageEvent":{"type":"text_delta","delta":"hello"}}'
  sleep ${delaySeconds}
  printf '%s\n' '{"type":"message_update","assistantMessageEvent":{"type":"text_delta","delta":" world"}}'
else
  printf 'hello'
  sleep ${delaySeconds}
  printf ' world'
fi
`,
	)
	await chmod(fakePi, 0o755)

	const port = await getFreePort()
	const proc = Bun.spawn([process.execPath, 'pi_shim.ts'], {
		cwd: projectDir,
		env: {
			...Bun.env,
			HOME: tmp,
			PATH: `${tmp}:${Bun.env.PATH ?? ''}`,
			PORT: String(port),
		},
		stdin: 'ignore',
		stdout: 'pipe',
		stderr: 'pipe',
	})
	const stdout = new Response(proc.stdout).text()
	const stderr = new Response(proc.stderr).text()
	const origin = `http://127.0.0.1:${port}`

	const stop = async () => {
		proc.kill()
		await proc.exited.catch(() => {})
		await Promise.all([stdout, stderr]).catch(() => {})
		await rm(tmp, { recursive: true, force: true })
	}

	for (let i = 0; i < 30; i += 1) {
		try {
			const response = await fetch(`${origin}/health`)
			if (response.ok) {
				const shim = { origin, stop }
				running.push(shim)
				return shim
			}
		} catch {}
		await sleep(100)
	}

	await stop()
	throw new Error('pi-shim did not start')
}

afterEach(async () => {
	await Promise.all(running.splice(0).map((shim) => shim.stop()))
})

describe('pi-shim chat completions', () => {
	test('returns normal OpenAI chat completion JSON', async () => {
		const { origin } = await startShim()

		const response = await fetch(`${origin}/v1/chat/completions`, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({
				model: 'pi-cloud',
				messages: [{ role: 'user', content: 'say hello' }],
				stream: false,
			}),
		})

		expect(response.status).toBe(200)
		const body = await response.json()
		expect(body).toMatchObject({
			object: 'chat.completion',
			model: 'pi-cloud',
			choices: [
				{
					index: 0,
					message: { role: 'assistant', content: 'hello world' },
					finish_reason: 'stop',
				},
			],
		})
	})

	test('returns OpenAI-compatible SSE chunks when streaming', async () => {
		const { origin } = await startShim(1)
		const startedAt = performance.now()

		const response = await fetch(`${origin}/v1/chat/completions`, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({
				model: 'pi-cloud',
				messages: [{ role: 'user', content: 'say hello' }],
				stream: true,
			}),
		})

		expect(response.status).toBe(200)
		expect(response.headers.get('content-type')).toContain('text/event-stream')
		expect(response.body).not.toBeNull()

		const reader = response.body!.getReader()
		const decoder = new TextDecoder()
		let text = ''
		while (!text.includes('"content":"hello"')) {
			const { done, value } = await reader.read()
			expect(done).toBe(false)
			text += decoder.decode(value, { stream: true })
		}
		expect(performance.now() - startedAt).toBeLessThan(800)

		while (true) {
			const { done, value } = await reader.read()
			if (done) break
			text += decoder.decode(value, { stream: true })
		}
		text += decoder.decode()

		const events = text
			.split('\n\n')
			.map((event) => event.trim())
			.filter(Boolean)
			.map((event) => event.replace(/^data: /, ''))

		expect(events.at(-1)).toBe('[DONE]')

		const chunks = events.slice(0, -1).map((event) => JSON.parse(event))
		expect(chunks[0]).toMatchObject({
			object: 'chat.completion.chunk',
			choices: [{ index: 0, delta: { role: 'assistant' }, finish_reason: null }],
		})
		expect(chunks.at(-1)).toMatchObject({
			object: 'chat.completion.chunk',
			choices: [{ index: 0, delta: {}, finish_reason: 'stop' }],
		})

		const content = chunks.map((chunk) => chunk.choices?.[0]?.delta?.content ?? '').join('')
		expect(content).toBe('hello world')
	})
})
