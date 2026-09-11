import { createHash, randomBytes } from "node:crypto";
import { realpathSync } from "node:fs";
import { basename, isAbsolute, join, resolve } from "node:path";

const AGENT_WORKSPACE_PATTERN = /^agents-[a-z0-9](?:[a-z0-9-]{0,62}[a-z0-9])?$/;
const SOURCE_WORKSPACE_PATTERN = /^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$/;

function commandText(command, args) {
	return [command, ...args].join(" ");
}

export function runProcess(command, args, options = {}) {
	const result = Bun.spawnSync([command, ...args], {
		cwd: options.cwd,
		env: options.env ?? process.env,
		stderr: "pipe",
		stdout: "pipe",
	});
	const stderr = result.stderr.toString().trim();
	const stdout = result.stdout.toString().trim();

	if (result.exitCode !== 0 && !options.allowFailure) {
		const detail = stderr || stdout || `exit ${result.exitCode}`;
		throw new Error(`${commandText(command, args)} failed: ${detail}`);
	}

	return { exitCode: result.exitCode, stderr, stdout };
}

export function runJj(cwd, args, options = {}) {
	const globalArgs = ["--no-pager", "--color=never"];
	if (options.ignoreWorkingCopy) globalArgs.push("--ignore-working-copy");
	return runProcess("jj", [...globalArgs, ...args], { cwd });
}

export function slugify(value) {
	return value
		.normalize("NFKD")
		.replace(/[\u0300-\u036f]/g, "")
		.toLowerCase()
		.replace(/[^a-z0-9]+/g, "-")
		.replace(/^-+|-+$/g, "")
		.slice(0, 24)
		.replace(/-+$/g, "");
}

export function createAgentIdentity(task, now = new Date(), nonce = randomBytes(4).toString("hex")) {
	const slug = slugify(task);
	if (!slug) throw new Error("Task slug must contain at least one letter or number.");
	const timestamp = now.toISOString().replace(/[-:]/g, "").replace(/\.\d{3}Z$/, "Z");
	const id = `${slug}-${timestamp.toLowerCase()}-${nonce.toLowerCase()}`;
	return {
		bookmark: `agents/${id}`,
		id,
		workspace: `agents-${id}`,
	};
}

export function agentDestination(repoRoot, workspace, env = process.env) {
	const home = env.HOME;
	if (!home) throw new Error("HOME is required.");
	const base = env.CODEX_AGENT_WORKSPACES ?? join(home, ".local", "share", "codex", "agent-workspaces");
	if (!isAbsolute(base)) throw new Error("CODEX_AGENT_WORKSPACES must be an absolute path.");
	const repoHash = createHash("sha256").update(realpathSync(repoRoot)).digest("hex").slice(0, 10);
	return join(base, `${slugify(basename(repoRoot)) || "repo"}-${repoHash}`, workspace);
}

function parseWorkspaceRows(output) {
	return output
		.split("\n")
		.filter(Boolean)
		.map((line) => {
			const separator = line.lastIndexOf("\t");
			if (separator < 1) throw new Error(`Unexpected jj workspace row: ${line}`);
			return { commitId: line.slice(separator + 1), name: line.slice(0, separator) };
		});
}

export function listWorkspaces(cwd) {
	const template = 'name ++ "\\t" ++ target.commit_id() ++ "\\n"';
	return parseWorkspaceRows(
		runJj(cwd, ["workspace", "list", "-T", template], { ignoreWorkingCopy: true }).stdout,
	);
}

export function revisionId(cwd, revision) {
	return runJj(cwd, ["log", "-r", revision, "--no-graph", "-T", 'commit_id ++ "\\n"'], {
		ignoreWorkingCopy: true,
	}).stdout;
}

export function revisionParents(cwd, revision) {
	const template = 'parents.map(|p| p.commit_id()).join("\\n") ++ "\\n"';
	const output = runJj(cwd, ["log", "-r", revision, "--no-graph", "-T", template], {
		ignoreWorkingCopy: true,
	}).stdout;
	return output ? output.split("\n") : [];
}

export function currentWorkspace(cwd, options = {}) {
	if (options.snapshot) runJj(cwd, ["status"]);
	const commitId = revisionId(cwd, "@");
	const matches = listWorkspaces(cwd).filter((workspace) => workspace.commitId === commitId);
	if (matches.length !== 1) {
		throw new Error(`Expected one current jj workspace for ${commitId}; found ${matches.length}.`);
	}
	return matches[0].name;
}

function requiredEnvironment(env, name) {
	const value = env[name];
	if (!value) throw new Error(`${name} is required; launch through codex-agent.`);
	return value;
}

export function agentContextFromEnv(env = process.env) {
	const agentRoot = requiredEnvironment(env, "CODEX_AGENT_ROOT");
	const bookmark = requiredEnvironment(env, "CODEX_AGENT_BOOKMARK");
	const sourceRoot = requiredEnvironment(env, "CODEX_AGENT_SOURCE_ROOT");
	const sourceWorkspace = requiredEnvironment(env, "CODEX_AGENT_SOURCE_WORKSPACE");
	const workspace = requiredEnvironment(env, "CODEX_AGENT_WORKSPACE");

	if (!AGENT_WORKSPACE_PATTERN.test(workspace)) {
		throw new Error(`Invalid agent workspace name: ${workspace}`);
	}
	if (!SOURCE_WORKSPACE_PATTERN.test(sourceWorkspace) || sourceWorkspace.startsWith("agents-")) {
		throw new Error(`Invalid source workspace name: ${sourceWorkspace}`);
	}
	if (bookmark !== `agents/${workspace.slice("agents-".length)}`) {
		throw new Error("Agent bookmark does not match its workspace.");
	}
	if (!isAbsolute(agentRoot) || !isAbsolute(sourceRoot)) {
		throw new Error("Agent and source roots must be absolute paths.");
	}
	if (basename(resolve(agentRoot)) !== workspace) {
		throw new Error("Agent workspace directory must match its agents-* workspace name.");
	}

	return {
		agentRoot: resolve(agentRoot),
		bookmark,
		sourceRoot: resolve(sourceRoot),
		sourceWorkspace,
		workspace,
	};
}

function samePath(left, right) {
	return realpathSync(left) === realpathSync(right);
}

export class AgentWorkspace {
	constructor(context) {
		this.context = context;
	}

	get agentRevision() {
		return `${this.context.workspace}@`;
	}

	get sourceRevision() {
		return `${this.context.sourceWorkspace}@`;
	}

	assertOwned() {
		const { agentRoot, sourceRoot, sourceWorkspace, workspace } = this.context;
		const actualAgentRoot = runJj(agentRoot, ["root"], { ignoreWorkingCopy: true }).stdout;
		const actualSourceRoot = runJj(sourceRoot, ["root"], { ignoreWorkingCopy: true }).stdout;
		if (!samePath(actualAgentRoot, agentRoot)) throw new Error("MCP is not running in its agent root.");
		if (!samePath(actualSourceRoot, sourceRoot)) throw new Error("Source workspace root changed.");
		if (currentWorkspace(agentRoot) !== workspace) throw new Error("Current workspace is not owned by this agent.");
		if (currentWorkspace(sourceRoot) !== sourceWorkspace) throw new Error("Source workspace identity changed.");
	}

	sync() {
		const { agentRoot, bookmark } = this.context;
		this.assertOwned();
		runJj(agentRoot, ["workspace", "update-stale"]);
		runJj(agentRoot, ["status"]);

		for (let attempt = 0; attempt < 3; attempt += 1) {
			const sourceBefore = revisionId(agentRoot, this.sourceRevision);
			const parents = revisionParents(agentRoot, this.agentRevision);
			if (parents.length !== 1 || parents[0] !== sourceBefore) {
				runJj(agentRoot, ["rebase", "-r", this.agentRevision, "-o", this.sourceRevision]);
				runJj(agentRoot, ["workspace", "update-stale"]);
			}

			const sourceAfter = revisionId(agentRoot, this.sourceRevision);
			const currentParents = revisionParents(agentRoot, this.agentRevision);
			if (sourceBefore === sourceAfter && currentParents.length === 1 && currentParents[0] === sourceAfter) {
				runJj(agentRoot, ["bookmark", "set", "-B", "-r", this.agentRevision, bookmark]);
				return { agent: revisionId(agentRoot, this.agentRevision), base: sourceAfter };
			}
		}

		throw new Error("Source workspace changed repeatedly; retry after its jj operations finish.");
	}

	status() {
		const synced = this.sync();
		const status = runJj(this.context.agentRoot, ["status"]).stdout;
		return `Base ${this.context.sourceWorkspace}@ ${synced.base.slice(0, 12)}\nAgent ${this.context.workspace}@ ${synced.agent.slice(0, 12)}\n\n${status}`;
	}

	diff() {
		this.sync();
		return runJj(
			this.context.agentRoot,
			["diff", "--from", this.sourceRevision, "--to", this.agentRevision],
			{ ignoreWorkingCopy: true },
		).stdout;
	}

	describe(message) {
		const description = message.trim().replace(/\s+/g, " ");
		if (!description || description.length > 200) {
			throw new Error("Description must contain 1-200 characters.");
		}
		this.sync();
		runJj(this.context.agentRoot, [
			"describe",
			"-r",
			this.agentRevision,
			"-m",
			`${this.context.bookmark}: ${description}`,
		]);
		runJj(this.context.agentRoot, [
			"bookmark",
			"set",
			"-B",
			"-r",
			this.agentRevision,
			this.context.bookmark,
		]);
		return `Described ${this.context.workspace}@ as ${this.context.bookmark}: ${description}`;
	}

	handoff() {
		const synced = this.sync();
		const stat = runJj(
			this.context.agentRoot,
			["diff", "--stat", "--from", this.sourceRevision, "--to", this.agentRevision],
			{ ignoreWorkingCopy: true },
		).stdout;
		return [
			`Workspace: ${this.context.workspace}`,
			`Bookmark: ${this.context.bookmark}`,
			`Path: ${this.context.agentRoot}`,
			`Base: ${this.context.sourceWorkspace}@ ${synced.base}`,
			`Agent: ${this.context.workspace}@ ${synced.agent}`,
			"",
			stat || "No agent changes.",
			"",
			`Review: jj diff --from ${this.sourceRevision} --to ${this.agentRevision}`,
			`Apply: jj squash --from ${this.agentRevision} --into @`,
		].join("\n");
	}
}
