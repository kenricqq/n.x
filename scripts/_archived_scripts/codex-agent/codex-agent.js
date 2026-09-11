#!/usr/bin/env bun

import { existsSync, mkdirSync } from "node:fs";
import { dirname } from "node:path";
import {
	AgentWorkspace,
	agentContextFromEnv,
	agentDestination,
	createAgentIdentity,
	currentWorkspace,
	runJj,
} from "./lib.js";
import { serveMcp } from "./mcp.js";

const USAGE = "usage: codex-agent <task-slug> [prompt ...]";

function agentEnvironment(context) {
	return {
		...process.env,
		CODEX_AGENT_BOOKMARK: context.bookmark,
		CODEX_AGENT_ROOT: context.agentRoot,
		CODEX_AGENT_SOURCE_ROOT: context.sourceRoot,
		CODEX_AGENT_SOURCE_WORKSPACE: context.sourceWorkspace,
		CODEX_AGENT_WORKSPACE: context.workspace,
	};
}

async function launch(args) {
	if (args.length === 0 || args[0] === "--help" || args[0] === "-h") {
		console.log(USAGE);
		return args.length === 0 ? 2 : 0;
	}

	const task = args[0];
	const prompt = args.slice(1).join(" ").trim();
	const sourceRoot = runJj(process.cwd(), ["root"], { ignoreWorkingCopy: true }).stdout;
	const sourceWorkspace = currentWorkspace(process.cwd(), { snapshot: true });
	if (sourceWorkspace.startsWith("agents-")) {
		throw new Error("Run codex-agent from a non-agent source workspace.");
	}

	const identity = createAgentIdentity(task);
	const agentRoot = agentDestination(sourceRoot, identity.workspace);
	if (existsSync(agentRoot)) throw new Error(`Agent workspace path already exists: ${agentRoot}`);
	mkdirSync(dirname(agentRoot), { recursive: true });

	try {
		runJj(process.cwd(), [
			"workspace",
			"add",
			"--name",
			identity.workspace,
			"-r",
			`${sourceWorkspace}@`,
			"-m",
			`${identity.bookmark}: ${task}`,
			agentRoot,
		]);
	} catch (error) {
		const detail = error instanceof Error ? error.message : String(error);
		throw new Error(`Failed to create agent workspace at ${agentRoot}. ${detail}`, { cause: error });
	}

	runJj(agentRoot, ["bookmark", "create", "-r", `${identity.workspace}@`, identity.bookmark]);
	const context = {
		agentRoot,
		bookmark: identity.bookmark,
		sourceRoot,
		sourceWorkspace,
		workspace: identity.workspace,
	};
	const workspace = new AgentWorkspace(context);
	workspace.sync();

	console.log(`Workspace: ${identity.workspace}`);
	console.log(`Bookmark: ${identity.bookmark}`);
	console.log(`Path: ${agentRoot}`);

	const codexArgs = ["--strict-config", "--profile", "agent", "-C", agentRoot];
	if (prompt) codexArgs.push(prompt);
	const child = Bun.spawn(["codex", ...codexArgs], {
		cwd: agentRoot,
		env: agentEnvironment(context),
		stderr: "inherit",
		stdin: "inherit",
		stdout: "inherit",
	});
	const exitCode = await child.exited;

	console.log("\nAgent handoff");
	console.log(workspace.handoff());
	return exitCode;
}

async function main() {
	const [command, ...args] = process.argv.slice(2);
	if (command === "mcp") {
		const workspace = new AgentWorkspace(agentContextFromEnv());
		workspace.assertOwned();
		await serveMcp(workspace);
		return 0;
	}
	return launch(command === undefined ? [] : [command, ...args]);
}

try {
	process.exitCode = await main();
} catch (error) {
	console.error(`codex-agent: ${error instanceof Error ? error.message : String(error)}`);
	process.exitCode = 1;
}
