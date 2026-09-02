const PI_PROVIDER = 'openai-codex',
	PI_MODEL = 'gpt-5.5',
	SERVED_MODEL = 'pi-cloud'
const PORT = Number(Bun.env.PORT ?? 4891)
const PI_CWD = process.env.HOME ?? '/tmp'
const RESPONSE_INSTRUCTION =
	'Return only the final answer. Do not include logs, tool output, or commentary.'
const CLIPPER_INSTRUCTION =
	'Obsidian Web Clipper request: first USER message is page context; final USER message contains prompts. Return only valid JSON with prompts_responses and no prose outside JSON. Keep summary-style answers at most 500 words.'
const CORS_HEADERS = {
	'Access-Control-Allow-Origin': '*',
	'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
	'Access-Control-Allow-Headers': 'Content-Type, Authorization, HTTP-Referer, X-Title',
	'Access-Control-Allow-Private-Network': 'true',
}

type JsonValue = null | string | number | boolean | JsonValue[] | { [key: string]: JsonValue }
type ChatMessage = { role: string; content: JsonValue }

const isJsonObject = (value: JsonValue | undefined): value is { [key: string]: JsonValue } =>
	typeof value === 'object' && value !== null && !Array.isArray(value)

const json = (value: JsonValue, status = 200): Response =>
	Response.json(value, { status, headers: CORS_HEADERS })

const streamHeaders = {
	...CORS_HEADERS,
	'Content-Type': 'text/event-stream;charset=utf-8',
	'Cache-Control': 'no-cache, no-transform',
	Connection: 'keep-alive',
	'X-Accel-Buffering': 'no',
}

const errorText = (error: unknown): string =>
	error instanceof Error ? error.message : typeof error === 'string' ? error : 'unknown error'

const contentText = (content: JsonValue): string =>
	typeof content === 'string'
		? content
		: Array.isArray(content)
			? content
					.map((part) =>
						typeof part === 'string'
							? part
							: isJsonObject(part) && typeof part.text === 'string'
								? part.text
								: ''
					)
					.filter(Boolean)
					.join('\n')
			: content === null
				? ''
				: (JSON.stringify(content) ?? '')

function parseChatRequest(input: JsonValue) {
	if (!isJsonObject(input)) return { model: SERVED_MODEL, messages: [], stream: false }
	const messages = Array.isArray(input.messages)
		? input.messages.flatMap((message): ChatMessage[] =>
				isJsonObject(message) && typeof message.role === 'string'
					? [{ role: message.role, content: message.content ?? null }]
					: []
			)
		: []
	return {
		model: typeof input.model === 'string' ? input.model : SERVED_MODEL,
		messages,
		stream: input.stream === true,
	}
}

function promptFrom(messages: ChatMessage[]): string {
	const transcript = messages
		.map((message) => `${message.role.toUpperCase()}:\n${contentText(message.content)}`)
		.join('\n\n')
	const instruction = messages.some(
		(message) =>
			message.role === 'system' && contentText(message.content).includes('prompts_responses')
	)
		? CLIPPER_INSTRUCTION
		: RESPONSE_INSTRUCTION
	return `${transcript}\n\n${instruction}`
}

const piArgs = (prompt: string, mode?: 'json') => [
	'pi',
	...(mode ? ['--mode', mode] : []),
	'--no-session',
	'--no-tools',
	'--provider',
	PI_PROVIDER,
	'--model',
	PI_MODEL,
	'--thinking',
	'xhigh',
	'--no-context-files',
	'-p',
	prompt,
]

const spawnPi = (prompt: string, mode?: 'json') =>
	Bun.spawn(piArgs(prompt, mode), {
		cwd: PI_CWD,
		stdin: 'ignore',
		stdout: 'pipe',
		stderr: 'pipe',
	})

async function runPi(prompt: string): Promise<string> {
	const proc = spawnPi(prompt)
	const [stdout, stderr, exitCode] = await Promise.all([
		new Response(proc.stdout).text(),
		new Response(proc.stderr).text(),
		proc.exited,
	])
	if (exitCode !== 0) throw new Error(stderr.trim() || `pi exited with code ${exitCode}`)
	return stdout.trim()
}

const completionResponse = (
	id: string,
	created: number,
	model: string,
	content: string
): JsonValue => ({
	id,
	object: 'chat.completion',
	created,
	model,
	choices: [{ index: 0, message: { role: 'assistant', content }, finish_reason: 'stop' }],
})

const completionChunk = (
	id: string,
	created: number,
	model: string,
	delta: { [key: string]: JsonValue },
	finishReason: JsonValue
): JsonValue => ({
	id,
	object: 'chat.completion.chunk',
	created,
	model,
	choices: [{ index: 0, delta, finish_reason: finishReason }],
})

const sse = (value: JsonValue | '[DONE]'): string =>
	value === '[DONE]' ? 'data: [DONE]\n\n' : `data: ${JSON.stringify(value)}\n\n`

function streamChat(
	id: string,
	created: number,
	model: string,
	prompt: string,
	signal: AbortSignal
): Response {
	return new Response(
		new ReadableStream<Uint8Array>({
			async start(controller) {
				const encode = new TextEncoder()
				const send = (value: JsonValue | '[DONE]') => controller.enqueue(encode.encode(sse(value)))
				const proc = spawnPi(prompt, 'json')
				const abort = () => proc.kill()
				signal.addEventListener('abort', abort, { once: true })

				try {
					send(completionChunk(id, created, model, { role: 'assistant' }, null))
					const stderr = new Response(proc.stderr).text()
					let buffer = ''
					const decoder = new TextDecoder()
					const reader = proc.stdout.getReader()
					while (true) {
						const { done, value } = await reader.read()
						buffer += done ? decoder.decode() : decoder.decode(value, { stream: true })
						for (;;) {
							const newline = buffer.indexOf('\n')
							if (newline === -1) break
							const line = buffer.slice(0, newline).trim()
							buffer = buffer.slice(newline + 1)
							if (!line) continue
							const event = JSON.parse(line) as {
								assistantMessageEvent?: { type?: string; delta?: string }
							}
							const delta = event.assistantMessageEvent?.delta
							if (event.assistantMessageEvent?.type === 'text_delta' && delta) {
								send(completionChunk(id, created, model, { content: delta }, null))
							}
						}
						if (done) break
					}
					const [errorOutput, exitCode] = await Promise.all([stderr, proc.exited])
					if (exitCode !== 0)
						throw new Error(errorOutput.trim() || `pi exited with code ${exitCode}`)
					send(completionChunk(id, created, model, {}, 'stop'))
				} catch (error) {
					send(
						completionChunk(
							id,
							created,
							model,
							{ content: `\n[pi-shim error: ${errorText(error)}]` },
							'stop'
						)
					)
				} finally {
					signal.removeEventListener('abort', abort)
					send('[DONE]')
					controller.close()
				}
			},
		}),
		{ headers: streamHeaders }
	)
}

async function chat(req: Request): Promise<Response> {
	try {
		const input = (await req.json()) as JsonValue
		const body = parseChatRequest(input)
		const prompt = promptFrom(body.messages)
		const now = Date.now()
		const id = `chatcmpl-pi-${now}`
		const created = Math.floor(now / 1000)
		console.log('[chat.completions input]', JSON.stringify(input) ?? '')
		if (body.stream) return streamChat(id, created, body.model, prompt, req.signal)
		return json(completionResponse(id, created, body.model, await runPi(prompt)))
	} catch (error) {
		return json({ error: { message: errorText(error), type: 'server_error' } }, 500)
	}
}

Bun.serve({
	port: PORT,
	fetch(req) {
		const { pathname } = new URL(req.url)
		if (req.method === 'OPTIONS') return new Response(null, { status: 204, headers: CORS_HEADERS })
		if (pathname === '/health') return json({ ok: true, provider: PI_PROVIDER, model: PI_MODEL })
		if (pathname === '/v1/models')
			return json({
				object: 'list',
				data: [{ id: SERVED_MODEL, object: 'model', owned_by: 'local' }],
			})
		if (pathname === '/v1/chat/completions' && req.method === 'POST') return chat(req)
		return json({ error: 'not found' }, 404)
	},
})

console.log(`Pi shim running at http://127.0.0.1:${PORT}/v1`)
