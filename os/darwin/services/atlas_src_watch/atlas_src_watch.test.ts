import { describe, expect, test } from 'bun:test'
import { existsSync } from 'node:fs'
import { chmod, mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'

import {
	baselineExisting,
	fileSig,
	findJobs,
	promptFor,
	readState,
	runJob,
	sourceHtml,
	sourceRel,
	type Config,
	type State,
} from './atlas_src_watch'

type FakePi = 'success' | 'fail'

type TestAtlas = {
	root: string
	logDir: string
	config: Config
	cleanup: () => Promise<void>
}

async function writeExecutable(path: string, content: string) {
	await writeFile(path, content)
	await chmod(path, 0o755)
}

async function makeAtlas(fakePi: FakePi = 'success'): Promise<TestAtlas> {
	const root = await mkdtemp(join(tmpdir(), 'atlas_src_watch-test-'))
	const logDir = join(root, 'logs')
	await mkdir(join(root, 'raw/assets'), { recursive: true })
	await mkdir(join(root, 'wiki/assets'), { recursive: true })
	await mkdir(logDir, { recursive: true })

	const pi = join(root, 'fake-pi')
	await writeExecutable(
		pi,
		fakePi === 'success'
			? `#!/usr/bin/env bash
set -euo pipefail
prompt="$1"
printf '%s' "$prompt" > "$LOG_DIR/prompt.txt"
html=$(printf '%s\n' "$prompt" | sed -n 's/^Use this exact HTML explainer path: //p' | head -n1)
test -n "$html"
mkdir -p "$(dirname "$html")"
printf '<html>ok</html>' > "$html"
`
			: `#!/usr/bin/env bash
exit 7
`,
	)

	const open = join(root, 'fake-open')
	await writeExecutable(
		open,
		`#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$1" >> "$LOG_DIR/opened.txt"
`,
	)

	return {
		root,
		logDir,
		config: {
			root,
			home: root,
			statePath: join(root, 'state.json'),
			stableMs: 0,
			pollMs: 1000,
			concurrency: 1,
			piCommand: [pi],
			openCommand: [open],
			env: { ...Bun.env, HOME: root, LOG_DIR: logDir },
		},
		cleanup: () => rm(root, { recursive: true, force: true }),
	}
}

describe('atlas_src_watch', () => {
	test('maps raw source names to stable explainer paths', () => {
		const root = '/vault'
		const abs = join(root, 'raw/clipper/Café & CFG!.md')

		expect(sourceRel(root, abs)).toBe('raw/clipper/Café & CFG!.md')
		expect(sourceHtml(root, abs)).toEqual({
			htmlRel: 'wiki/assets/cafe-cfg-explainer.html',
			htmlAbs: join(root, 'wiki/assets/cafe-cfg-explainer.html'),
		})
	})

	test('baselines existing sources and queues later changes only', async () => {
		const atlas = await makeAtlas()
		try {
			const source = join(atlas.root, 'raw/Existing.md')
			await writeFile(source, 'old')
			const state: State = {}

			expect(baselineExisting(atlas.config, state)).toBe(1)
			expect(findJobs(atlas.config, state, new Set(), Date.now() + 1000)).toEqual([])

			await writeFile(source, 'old updated')
			const jobs = findJobs(atlas.config, state, new Set(), Date.now() + 1000)

			expect(jobs.map((job) => job.rel)).toEqual(['raw/Existing.md'])
		} finally {
			await atlas.cleanup()
		}
	})

	test('scanner ignores assets, unstable files, and busy jobs', async () => {
		const atlas = await makeAtlas()
		try {
			const keep = join(atlas.root, 'raw/Keep.md')
			await writeFile(keep, 'keep')
			await writeFile(join(atlas.root, 'raw/assets/Asset.md'), 'asset')
			const file = fileSig(keep)!
			const state: State = {}
			const stableConfig = { ...atlas.config, stableMs: 1000 }

			expect(findJobs(stableConfig, state, new Set(), file.mtimeMs + 999)).toEqual([])

			const [job] = findJobs(stableConfig, state, new Set(), file.mtimeMs + 1001)
			expect(job.rel).toBe('raw/Keep.md')
			expect(
				findJobs(stableConfig, state, new Set([`${job.rel}\n${job.sig}`]), file.mtimeMs + 1001),
			).toEqual([])
		} finally {
			await atlas.cleanup()
		}
	})

	test('successful ingest records state and opens generated HTML', async () => {
		const atlas = await makeAtlas('success')
		try {
			const source = join(atlas.root, 'raw/Clip Title.md')
			await writeFile(source, 'clip')
			const state: State = {}
			const [job] = findJobs(atlas.config, state, new Set(), Date.now() + 1000)

			expect(await runJob(atlas.config, state, job)).toBe(true)
			expect(existsSync(job.htmlAbs)).toBe(true)
			expect(state[job.rel]).toMatchObject({ sig: job.sig, status: 'done', html: job.htmlRel })
			expect(readState(atlas.config.statePath)[job.rel]).toMatchObject({
				status: 'done',
				html: job.htmlRel,
			})
			expect(await readFile(join(atlas.logDir, 'opened.txt'), 'utf8')).toBe(`${job.htmlAbs}\n`)

			const prompt = await readFile(join(atlas.logDir, 'prompt.txt'), 'utf8')
			expect(prompt).toBe(promptFor(job))
			expect(prompt).toContain('ingest raw/Clip Title.md')
			expect(prompt).toContain(`Use this exact HTML explainer path: ${job.htmlRel}`)
		} finally {
			await atlas.cleanup()
		}
	})

	test('failed ingest records failure and does not open HTML', async () => {
		const atlas = await makeAtlas('fail')
		try {
			const source = join(atlas.root, 'raw/Broken.md')
			await writeFile(source, 'broken')
			const state: State = {}
			const [job] = findJobs(atlas.config, state, new Set(), Date.now() + 1000)

			expect(await runJob(atlas.config, state, job)).toBe(false)
			expect(existsSync(job.htmlAbs)).toBe(false)
			expect(existsSync(join(atlas.logDir, 'opened.txt'))).toBe(false)
			expect(state[job.rel]).toMatchObject({ sig: job.sig, status: 'failed', error: 'pi exited 7' })
			expect(readState(atlas.config.statePath)[job.rel]).toMatchObject({
				status: 'failed',
				error: 'pi exited 7',
			})
		} finally {
			await atlas.cleanup()
		}
	})
})
