import { afterEach, describe, expect, test } from "bun:test";
import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
	AgentWorkspace,
	agentContextFromEnv,
	createAgentIdentity,
	currentWorkspace,
	revisionId,
	revisionParents,
	runJj,
} from "./lib.js";
import { handleMcpRequest } from "./mcp.js";

const temporaryDirectories = [];

afterEach(() => {
	for (const directory of temporaryDirectories.splice(0)) {
		rmSync(directory, { force: true, recursive: true });
	}
});

describe("agent identity", () => {
	test("prefixes workspace and bookmark with agents", () => {
		const identity = createAgentIdentity(
			"Fix the Login Flow",
			new Date("2026-07-09T20:30:00.000Z"),
			"a1b2c3d4",
		);
		expect(identity).toEqual({
			bookmark: "agents/fix-the-login-flow-20260709t203000z-a1b2c3d4",
			id: "fix-the-login-flow-20260709t203000z-a1b2c3d4",
			workspace: "agents-fix-the-login-flow-20260709t203000z-a1b2c3d4",
		});
	});

	test("rejects a bookmark that is not owned by its workspace", () => {
		expect(() =>
			agentContextFromEnv({
				CODEX_AGENT_BOOKMARK: "main",
				CODEX_AGENT_ROOT: "/tmp/agents-task-20260709t203000z-a1b2c3d4",
				CODEX_AGENT_SOURCE_ROOT: "/tmp/source",
				CODEX_AGENT_SOURCE_WORKSPACE: "default",
				CODEX_AGENT_WORKSPACE: "agents-task-20260709t203000z-a1b2c3d4",
			}),
		).toThrow("bookmark does not match");
	});
});

describe("MCP protocol", () => {
	test("exposes only fixed-scope tools", async () => {
		const response = await handleMcpRequest(
			{ id: 1, jsonrpc: "2.0", method: "tools/list" },
			{},
		);
		expect(response.result.tools.map((tool) => tool.name)).toEqual([
			"sync",
			"status",
			"diff",
			"describe",
			"handoff",
		]);
		expect(response.result.tools.every((tool) => !tool.inputSchema.properties.revision)).toBe(true);
	});

	test("does not pass arbitrary describe fields", async () => {
		const workspace = { describe: () => "unexpected" };
		const response = await handleMcpRequest(
			{
				id: 2,
				jsonrpc: "2.0",
				method: "tools/call",
				params: { arguments: { message: "ok", revision: "main@" }, name: "describe" },
			},
			workspace,
		);
		expect(response.result.isError).toBe(true);
	});
});

describe("jj ownership and freshness", () => {
	test("rebases only agent changes onto the source workspace current @", async () => {
		const root = mkdtempSync(join(tmpdir(), "codex-agent-test-"));
		temporaryDirectories.push(root);
		const sourceRoot = join(root, "source");
		mkdirSync(sourceRoot);
		runJj(sourceRoot, ["git", "init", "--colocate", "."]);
		writeFileSync(join(sourceRoot, "base.txt"), "base\n");
		runJj(sourceRoot, ["status"]);

		const sourceWorkspace = currentWorkspace(sourceRoot);
		const identity = createAgentIdentity(
			"integration",
			new Date("2026-07-09T20:30:00.000Z"),
			"a1b2c3d4",
		);
		const agentRoot = join(root, identity.workspace);
		runJj(sourceRoot, [
			"workspace",
			"add",
			"--name",
			identity.workspace,
			"-r",
			`${sourceWorkspace}@`,
			agentRoot,
		]);
		runJj(agentRoot, ["bookmark", "create", "-r", `${identity.workspace}@`, identity.bookmark]);

		const workspace = new AgentWorkspace({
			agentRoot,
			bookmark: identity.bookmark,
			sourceRoot,
			sourceWorkspace,
			workspace: identity.workspace,
		});
		writeFileSync(join(agentRoot, "agent.txt"), "agent only\n");
		expect(workspace.diff()).toContain("agent.txt");

		writeFileSync(join(sourceRoot, "base.txt"), "new source base\n");
		runJj(sourceRoot, ["status"]);
		const sourceBeforeBroker = revisionId(sourceRoot, `${sourceWorkspace}@`);
		const diff = workspace.diff();
		const sourceAfterBroker = revisionId(sourceRoot, `${sourceWorkspace}@`);

		expect(sourceAfterBroker).toBe(sourceBeforeBroker);
		expect(revisionParents(agentRoot, `${identity.workspace}@`)).toEqual([sourceBeforeBroker]);
		expect(diff).toContain("agent.txt");
		expect(diff).not.toContain("base.txt");

		const mcp = Bun.spawn(["bun", join(import.meta.dir, "codex-agent.js"), "mcp"], {
			cwd: agentRoot,
			env: {
				...process.env,
				CODEX_AGENT_BOOKMARK: identity.bookmark,
				CODEX_AGENT_ROOT: agentRoot,
				CODEX_AGENT_SOURCE_ROOT: sourceRoot,
				CODEX_AGENT_SOURCE_WORKSPACE: sourceWorkspace,
				CODEX_AGENT_WORKSPACE: identity.workspace,
			},
			stderr: "pipe",
			stdin: "pipe",
			stdout: "pipe",
		});
		mcp.stdin.write(
			`${JSON.stringify({
				id: 1,
				jsonrpc: "2.0",
				method: "initialize",
				params: { capabilities: {}, clientInfo: { name: "test", version: "1" }, protocolVersion: "2025-11-25" },
			})}\n`,
		);
		mcp.stdin.write(`${JSON.stringify({ id: 2, jsonrpc: "2.0", method: "tools/list" })}\n`);
		mcp.stdin.end();
		await expect(mcp.exited).resolves.toBe(0);
		const responses = (await mcp.stdout.text())
			.trim()
			.split("\n")
			.map((line) => JSON.parse(line));
		expect(responses[0].result.protocolVersion).toBe("2025-11-25");
		expect(responses[1].result.tools.map((tool) => tool.name)).toEqual([
			"sync",
			"status",
			"diff",
			"describe",
			"handoff",
		]);
	});
});
