const PROTOCOL_VERSIONS = ["2025-11-25", "2025-06-18", "2025-03-26", "2024-11-05"];

export const tools = [
	{
		annotations: { destructiveHint: false, idempotentHint: true, readOnlyHint: false },
		description: "Snapshot this agent workspace and rebase only its working-copy commit onto the source workspace's recorded current @.",
		inputSchema: { additionalProperties: false, properties: {}, type: "object" },
		name: "sync",
	},
	{
		annotations: { destructiveHint: false, idempotentHint: true, readOnlyHint: false },
		description: "Sync, then show status for this agent-owned workspace.",
		inputSchema: { additionalProperties: false, properties: {}, type: "object" },
		name: "status",
	},
	{
		annotations: { destructiveHint: false, idempotentHint: true, readOnlyHint: false },
		description: "Sync, then show only this agent's diff against the source workspace's current @.",
		inputSchema: { additionalProperties: false, properties: {}, type: "object" },
		name: "diff",
	},
	{
		annotations: { destructiveHint: false, idempotentHint: false, readOnlyHint: false },
		description: "Sync, then set an agents/-prefixed description on this agent-owned change.",
		inputSchema: {
			additionalProperties: false,
			properties: { message: { maxLength: 200, minLength: 1, type: "string" } },
			required: ["message"],
			type: "object",
		},
		name: "describe",
	},
	{
		annotations: { destructiveHint: false, idempotentHint: true, readOnlyHint: false },
		description: "Sync and return the owned workspace, bookmark, base, review command, and diff summary for user handoff.",
		inputSchema: { additionalProperties: false, properties: {}, type: "object" },
		name: "handoff",
	},
];

function success(id, result) {
	return { id, jsonrpc: "2.0", result };
}

function failure(id, code, message) {
	return { error: { code, message }, id, jsonrpc: "2.0" };
}

function toolResult(text, isError = false) {
	return { content: [{ text, type: "text" }], isError };
}

function assertEmptyArguments(args) {
	if (args === undefined) return;
	if (!args || typeof args !== "object" || Array.isArray(args) || Object.keys(args).length > 0) {
		throw new Error("Tool takes no arguments.");
	}
}

async function callTool(name, args, workspace) {
	switch (name) {
		case "sync": {
			assertEmptyArguments(args);
			const synced = workspace.sync();
			return `Synced agent ${synced.agent} onto base ${synced.base}.`;
		}
		case "status":
			assertEmptyArguments(args);
			return workspace.status();
		case "diff":
			assertEmptyArguments(args);
			return workspace.diff();
		case "describe":
			if (!args || typeof args.message !== "string" || Object.keys(args).some((key) => key !== "message")) {
				throw new Error("describe requires only a string message.");
			}
			return workspace.describe(args.message);
		case "handoff":
			assertEmptyArguments(args);
			return workspace.handoff();
		default:
			throw new Error(`Unknown tool: ${name}`);
	}
}

export async function handleMcpRequest(request, workspace) {
	if (!request || request.jsonrpc !== "2.0" || typeof request.method !== "string") {
		return failure(request?.id ?? null, -32600, "Invalid JSON-RPC request.");
	}
	if (request.id === undefined) return null;

	switch (request.method) {
		case "initialize": {
			const requested = request.params?.protocolVersion;
			const protocolVersion = PROTOCOL_VERSIONS.includes(requested) ? requested : PROTOCOL_VERSIONS[0];
			return success(request.id, {
				capabilities: { tools: { listChanged: false } },
				instructions: "Use only these fixed-scope tools for Jujutsu. They can mutate only the launcher-bound agents-* workspace and bookmark.",
				protocolVersion,
				serverInfo: { name: "codex-agent-jj", version: "1.0.0" },
			});
		}
		case "ping":
			return success(request.id, {});
		case "tools/list":
			return success(request.id, { tools });
		case "tools/call":
			try {
				return success(
					request.id,
					toolResult(await callTool(request.params?.name, request.params?.arguments, workspace)),
				);
			} catch (error) {
				return success(request.id, toolResult(error instanceof Error ? error.message : String(error), true));
			}
		default:
			return failure(request.id, -32601, `Method not found: ${request.method}`);
	}
}

export async function serveMcp(workspace, input = Bun.stdin.stream()) {
	const decoder = new TextDecoder();
	let buffer = "";

	for await (const chunk of input) {
		buffer += decoder.decode(chunk, { stream: true });
		let newline = buffer.indexOf("\n");
		while (newline >= 0) {
			const line = buffer.slice(0, newline).replace(/\r$/, "");
			buffer = buffer.slice(newline + 1);
			if (line) {
				let response;
				try {
					// jj calls must stay ordered; concurrent tool calls could race the owned workspace.
					// eslint-disable-next-line no-await-in-loop
					response = await handleMcpRequest(JSON.parse(line), workspace);
				} catch (error) {
					response = failure(null, -32700, error instanceof Error ? error.message : "Parse error.");
				}
				if (response) process.stdout.write(`${JSON.stringify(response)}\n`);
			}
			newline = buffer.indexOf("\n");
		}
	}
}
