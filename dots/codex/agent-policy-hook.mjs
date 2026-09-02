import { spawnSync } from 'node:child_process'
import { realpathSync } from 'node:fs'
import { basename, isAbsolute, relative } from 'node:path'

const MAX_INPUT_BYTES = 1024 * 1024
const IMPECCABLE_HOOK = '/etc/codex/hooks/impeccable/scripts/hook.mjs'

async function readInput() {
	const chunks = []
	let size = 0

	for await (const chunk of process.stdin) {
		const buffer = Buffer.from(chunk)
		size += buffer.length

		if (size > MAX_INPUT_BYTES) {
			throw new Error('Hook input exceeded 1 MiB')
		}

		chunks.push(buffer)
	}

	return Buffer.concat(chunks).toString('utf8')
}

function emitBlock(event, reason) {
	if (event === 'PreToolUse') {
		process.stdout.write(
			JSON.stringify({
				hookSpecificOutput: {
					hookEventName: 'PreToolUse',
					permissionDecision: 'deny',
					permissionDecisionReason: reason,
				},
			})
		)
		return
	}

	if (event === 'UserPromptSubmit') {
		process.stdout.write(
			JSON.stringify({
				decision: 'block',
				reason,
			})
		)
		return
	}

	process.stdout.write(
		JSON.stringify({
			continue: false,
			stopReason: reason,
			systemMessage: reason,
		})
	)
}

function canonicalEnvPath(name) {
	const value = process.env[name]

	if (!value || !isAbsolute(value)) {
		throw new Error(`${name} must be an absolute path`)
	}

	return realpathSync(value)
}

function isInside(path, root) {
	const rel = relative(root, path)
	return rel === '' || (!rel.startsWith('..') && !isAbsolute(rel))
}

function validateAgentContext(input, requireRootCwd = false) {
	const workspace = canonicalEnvPath('CODEX_AGENT_WORKSPACE')
	const cwd = realpathSync(input.cwd)
	const tmpdir = canonicalEnvPath('TMPDIR')

	if (!/^agents-[A-Za-z0-9._-]+$/.test(basename(workspace))) {
		throw new Error('Agent workspace name must match agents-*')
	}

	if (requireRootCwd ? cwd !== workspace : !isInside(cwd, workspace)) {
		throw new Error('Session cwd is outside the assigned agent workspace')
	}

	if (!isInside(tmpdir, workspace)) {
		throw new Error('TMPDIR must be located inside the agent workspace')
	}

	const bookmark = process.env.CODEX_AGENT_BOOKMARK ?? ''

	if (!/^agents\/[A-Za-z0-9._/-]+$/.test(bookmark) || bookmark.split('/').includes('..')) {
		throw new Error('CODEX_AGENT_BOOKMARK must name one agents/* bookmark')
	}

	for (const name of [
		'CODEX_AGENT_ROOT',
		'CODEX_AGENT_SOURCE_ROOT',
		'CODEX_AGENT_SOURCE_WORKSPACE',
	]) {
		canonicalEnvPath(name)
	}
}

const secretPatterns = [
	['OpenAI API key', /\bsk-(?:proj-|svcacct-)?[A-Za-z0-9_-]{20,}\b/],
	['GitHub token', /\b(?:gh[pousr]_[A-Za-z0-9]{36,255}|github_pat_[A-Za-z0-9_]{20,})\b/],
	['AWS access key', /\b(?:AKIA|ASIA)[A-Z0-9]{16}\b/],
	['Linear API key', /\blin_(?:api|oauth)_[A-Za-z0-9_-]{20,}\b/],
	['GitLab token', /\bglpat-[A-Za-z0-9_-]{20,}\b/],
	['npm token', /\bnpm_[A-Za-z0-9]{30,}\b/],
	['Slack token', /\bxox[baprs]-[A-Za-z0-9-]{20,}\b/],
	['Stripe live key', /\b(?:sk|rk)_live_[A-Za-z0-9]{16,}\b/],
	['Google API key', /\bAIza[A-Za-z0-9_-]{30,}\b/],
	['private key', /-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/],
	['credential-bearing URL', /\b[a-z][a-z0-9+.-]*:\/\/[^\s/:]+:[^\s/@]+@/i],
]

function scanPrompt(prompt) {
	for (const [label, pattern] of secretPatterns) {
		if (pattern.test(prompt)) return label
	}

	return null
}

function obviousVcsCommand(command) {
	return /(^|[\s;&|()])(?:["']?\/[^\s;&|()"']+\/)?["']?(?:git|jj)["']?(?=$|[\s;&|()])/i.test(
		command
	)
}

function runImpeccable(raw, input) {
	const result = spawnSync(process.execPath, [realpathSync(IMPECCABLE_HOOK)], {
		cwd: realpathSync(input.cwd),
		env: process.env,
		input: raw,
		encoding: 'utf8',
		timeout: 12_000,
		maxBuffer: 1024 * 1024,
	})

	if (result.stdout) process.stdout.write(result.stdout)
	if (result.stderr) process.stderr.write(result.stderr)
	if (result.error) throw result.error

	if (result.status !== 0) {
		throw new Error(`Impeccable hook exited with status ${result.status}`)
	}
}

let raw
let input

try {
	raw = await readInput()
	input = JSON.parse(raw)
} catch (error) {
	process.stderr.write(`Agent hook rejected malformed input: ${error.message}\n`)
	process.exit(2)
}

const event = input.hook_event_name

try {
	if (event === 'UserPromptSubmit') {
		if (typeof input.prompt !== 'string') {
			emitBlock(event, 'Prompt secret scan failed closed: prompt was missing.')
		} else {
			const label = scanPrompt(input.prompt)

			if (label) {
				emitBlock(event, `Possible ${label} detected. Remove it before continuing.`)
			}
		}
	} else if (event === 'SessionStart') {
		validateAgentContext(input, true)
	} else if (event === 'PreToolUse') {
		validateAgentContext(input)

		const command = input.tool_input?.command

		if (typeof command !== 'string') {
			emitBlock(event, 'Agent shell command was missing from hook input.')
		} else if (obviousVcsCommand(command)) {
			emitBlock(event, 'Git and Jujutsu shell commands are disabled; use agent-jj.')
		}
	} else if (event === 'PostToolUse') {
		validateAgentContext(input)
		runImpeccable(raw, input)
	}
} catch (error) {
	emitBlock(event, `Agent policy failed closed: ${error.message}`)
}
