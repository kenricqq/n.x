import {
	existsSync,
	mkdirSync,
	readdirSync,
	readFileSync,
	renameSync,
	statSync,
	writeFileSync,
	watch,
} from 'node:fs'
import { basename, dirname, extname, join, relative, sep } from 'node:path'

export type SourceState = {
	sig: string
	status: 'seen' | 'done' | 'failed'
	html?: string
	error?: string
	at?: string
}

export type State = Record<string, SourceState>

export type Config = {
	root: string
	home: string
	statePath: string
	stableMs: number
	pollMs: number
	concurrency: number
	piCommand: string[]
	openCommand: string[]
	env: Record<string, string>
}

export type Job = {
	abs: string
	rel: string
	sig: string
	htmlAbs: string
	htmlRel: string
}

type Env = Record<string, string | undefined>

const ignoredDirs = new Set(['assets', '.git', '.obsidian', '.trash'])
const nowIso = () => new Date().toISOString()
const numberEnv = (value: string | undefined, fallback: number, min: number) =>
	Math.max(min, Number(value ?? fallback) || fallback)

function commandEnv(value: string | undefined, fallback: string[]): string[] {
	if (!value) return fallback
	const parsed = JSON.parse(value) as unknown
	if (
		!Array.isArray(parsed) ||
		parsed.length === 0 ||
		parsed.some((item) => typeof item !== 'string')
	) {
		throw new Error(`invalid command JSON: ${value}`)
	}
	return parsed
}

function stringEnv(env: Env): Record<string, string> {
	return Object.fromEntries(
		Object.entries(env).filter((entry): entry is [string, string] => typeof entry[1] === 'string'),
	)
}

export function configFromEnv(env: Env = Bun.env): Config {
	const home = env.HOME ?? '/tmp'
	const root = env.ATLAS_SRC_WATCH_ROOT ?? join(home, 'KTQQ/docs/Ideaverse/Atlas')
	return {
		root,
		home,
		statePath: env.ATLAS_SRC_WATCH_STATE_PATH ?? join(home, '.cache/atlas_src_watch/state.json'),
		stableMs: numberEnv(env.ATLAS_SRC_WATCH_STABLE_MS, 3000, 100),
		pollMs: numberEnv(env.ATLAS_SRC_WATCH_POLL_MS, 10000, 1000),
		concurrency: numberEnv(env.ATLAS_SRC_WATCH_CONCURRENCY, 1, 1),
		piCommand: commandEnv(env.ATLAS_SRC_WATCH_PI_COMMAND_JSON, ['pi']),
		openCommand: commandEnv(env.ATLAS_SRC_WATCH_OPEN_COMMAND_JSON, ['/usr/bin/open']),
		env: {
			...stringEnv(env),
			HOME: home,
			BUN_INSTALL: env.BUN_INSTALL ?? join(home, '.cache/.bun'),
		},
	}
}

export function slug(input: string): string {
	return (
		input
			.normalize('NFKD')
			.replace(/[\u0300-\u036f]/g, '')
			.toLowerCase()
			.replace(/[^a-z0-9]+/g, '-')
			.replace(/^-+|-+$/g, '')
			.slice(0, 80)
			.replace(/-+$/g, '') || 'source'
	)
}

export function sourceHtml(root: string, abs: string) {
	const htmlRel = `wiki/assets/${slug(basename(abs, extname(abs)))}-explainer.html`
	return { htmlRel, htmlAbs: join(root, ...htmlRel.split('/')) }
}

export function sourceRel(root: string, abs: string): string {
	return relative(root, abs).split(sep).join('/')
}

export function listSources(dir: string): string[] {
	return readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
		if (ignoredDirs.has(entry.name)) return []
		const abs = join(dir, entry.name)
		if (entry.isDirectory()) return listSources(abs)
		return entry.isFile() && entry.name.endsWith('.md') ? [abs] : []
	})
}

export function fileSig(abs: string) {
	try {
		const stats = statSync(abs)
		return stats.isFile()
			? { sig: `${Math.round(stats.mtimeMs)}:${stats.size}`, mtimeMs: stats.mtimeMs }
			: undefined
	} catch {
		return undefined
	}
}

export function readState(path: string): State {
	if (!existsSync(path)) return {}
	try {
		return JSON.parse(readFileSync(path, 'utf8')) as State
	} catch {
		renameSync(path, `${path}.bad-${Date.now()}`)
		return {}
	}
}

export function writeState(path: string, state: State) {
	mkdirSync(dirname(path), { recursive: true })
	const temp = `${path}.tmp`
	writeFileSync(temp, `${JSON.stringify(state, null, 2)}\n`)
	renameSync(temp, path)
}

export function baselineExisting(config: Config, state: State): number {
	let count = 0
	for (const abs of listSources(join(config.root, 'raw'))) {
		const sig = fileSig(abs)?.sig
		const rel = sourceRel(config.root, abs)
		if (!sig || state[rel]) continue
		state[rel] = { sig, status: 'seen', at: nowIso() }
		count += 1
	}
	writeState(config.statePath, state)
	return count
}

export function findJobs(
	config: Config,
	state: State,
	busy = new Set<string>(),
	at = Date.now(),
): Job[] {
	const jobs: Job[] = []
	for (const abs of listSources(join(config.root, 'raw'))) {
		const file = fileSig(abs)
		if (!file || at - file.mtimeMs < config.stableMs) continue

		const rel = sourceRel(config.root, abs)
		if (state[rel]?.sig === file.sig) continue

		const key = `${rel}\n${file.sig}`
		if (busy.has(key)) continue

		jobs.push({ abs, rel, sig: file.sig, ...sourceHtml(config.root, abs) })
	}
	return jobs
}

export function promptFor(job: Job): string {
	return [
		`ingest ${job.rel}`,
		'',
		'Automation context: Obsidian Web Clipper created or changed this raw source.',
		`Use this exact HTML explainer path: ${job.htmlRel}`,
		'Iterate until quality is high. Screenshot result to diagnose problems.',
		`When complete, ensure ${job.htmlRel} exists.`,
		'Do not ask follow-up questions. Exit after the ingest is complete.',
	].join('\n')
}

export async function runJob(config: Config, state: State, job: Job): Promise<boolean> {
	const proc = Bun.spawn([...config.piCommand, promptFor(job)], {
		cwd: config.root,
		env: config.env,
		stdout: 'inherit',
		stderr: 'inherit',
	})
	const exitCode = await proc.exited

	if (exitCode === 0 && existsSync(job.htmlAbs)) {
		state[job.rel] = { sig: job.sig, status: 'done', html: job.htmlRel, at: nowIso() }
		writeState(config.statePath, state)
		await Bun.spawn([...config.openCommand, job.htmlAbs], { env: config.env }).exited
		return true
	}

	state[job.rel] = {
		sig: job.sig,
		status: 'failed',
		error: exitCode === 0 ? `missing ${job.htmlRel}` : `pi exited ${exitCode}`,
		at: nowIso(),
	}
	writeState(config.statePath, state)
	return false
}

export function ensureAtlasDirs(config: Config) {
	mkdirSync(join(config.root, 'raw/clipper'), { recursive: true })
	mkdirSync(join(config.root, 'wiki/assets'), { recursive: true })
	mkdirSync(dirname(config.statePath), { recursive: true })
}

export function log(message: string) {
	console.log(`${nowIso()} ${message}`)
}

export async function main(config = configFromEnv()) {
	ensureAtlasDirs(config)
	const hadState = existsSync(config.statePath)
	const state = readState(config.statePath)
	if (!hadState) log(`initialized ${baselineExisting(config, state)} existing sources`)

	const queue: Job[] = []
	const queued = new Set<string>()
	const active = new Set<string>()
	let timer: ReturnType<typeof setTimeout> | undefined

	const schedule = (delay = 500) => {
		if (timer) clearTimeout(timer)
		timer = setTimeout(scan, delay)
	}

	const drain = () => {
		while (active.size < config.concurrency && queue.length > 0) {
			const job = queue.shift()!
			const key = `${job.rel}\n${job.sig}`
			queued.delete(key)
			if (fileSig(job.abs)?.sig !== job.sig) continue

			active.add(key)
			log(`ingest start ${job.rel}`)
			void runJob(config, state, job)
				.then((ok) => log(`ingest ${ok ? 'done' : 'failed'} ${job.rel}`))
				.catch((error) => {
					state[job.rel] = { sig: job.sig, status: 'failed', error: String(error), at: nowIso() }
					writeState(config.statePath, state)
					log(`ingest failed ${job.rel}: ${String(error)}`)
				})
				.finally(() => {
					active.delete(key)
					drain()
				})
		}
	}

	function scan() {
		timer = undefined
		const busy = new Set([...queued, ...active])
		for (const job of findJobs(config, state, busy)) {
			const key = `${job.rel}\n${job.sig}`
			queued.add(key)
			queue.push(job)
			log(`queued ${job.rel} -> ${job.htmlRel}`)
		}
		drain()
	}

	try {
		watch(join(config.root, 'raw'), { recursive: true }, (_event, filename) => {
			if (!filename || String(filename).endsWith('.md')) schedule()
		})
	} catch (error) {
		log(`watch unavailable; polling only: ${String(error)}`)
	}
	setInterval(scan, config.pollMs)
	schedule(0)
	log(`watching ${join(config.root, 'raw')} concurrency=${config.concurrency}`)
	await new Promise(() => {})
}

if (import.meta.main) {
	main().catch((error) => {
		console.error(error)
		process.exit(1)
	})
}
