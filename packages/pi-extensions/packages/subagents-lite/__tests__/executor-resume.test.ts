import { EventEmitter } from "node:events";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { PassThrough } from "node:stream";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { AgentConfig } from "../src/agents/agents.js";
import { createSubagentExecutor } from "../src/runs/foreground/subagent-executor.js";
import type { SubagentState } from "../src/shared/types.js";

const spawnMock = vi.hoisted(() => vi.fn());

vi.mock("node:child_process", async (importOriginal) => {
	const original = await importOriginal<typeof import("node:child_process")>();
	return { ...original, spawn: spawnMock };
});

function assistantEvent(): string {
	return JSON.stringify({
		type: "message_end",
		message: {
			role: "assistant",
			content: [{ type: "text", text: "continued" }],
			api: "test",
			provider: "test",
			model: "test-model",
			usage: {
				input: 1,
				output: 1,
				cacheRead: 0,
				cacheWrite: 0,
				totalTokens: 2,
				cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 },
			},
			stopReason: "stop",
			timestamp: Date.now(),
		},
	});
}

function fakeChildProcess() {
	const processEmitter = new EventEmitter() as EventEmitter & {
		stdout: PassThrough;
		stderr: PassThrough;
		killed: boolean;
		kill: ReturnType<typeof vi.fn>;
	};
	processEmitter.stdout = new PassThrough();
	processEmitter.stderr = new PassThrough();
	processEmitter.killed = false;
	processEmitter.kill = vi.fn(() => true);
	queueMicrotask(() => {
		processEmitter.stdout.write(`${assistantEvent()}\n`);
		processEmitter.stdout.end();
		processEmitter.stderr.end();
		processEmitter.emit("exit", 0, null);
		processEmitter.emit("close", 0, null);
	});
	return processEmitter;
}

function createState(): SubagentState {
	return {
		baseCwd: "",
		currentSessionId: "parent-session",
		subagentInProgress: false,
		subagentSpawns: { sessionId: "parent-session", count: 0 },
		asyncJobs: new Map(),
		foregroundRuns: new Map(),
		foregroundControls: new Map(),
		lastForegroundControlId: null,
		pendingForegroundControlNotices: new Map(),
		cleanupTimers: new Map(),
		lastUiContext: null,
		poller: null,
		completionSeen: new Map(),
		watcher: null,
		watcherRestartTimer: null,
		resultFileCoalescer: { schedule: () => false, clear: () => {} },
	};
}

const agent: AgentConfig = {
	name: "explore",
	description: "Explore",
	tools: ["read"],
	systemPromptMode: "append",
	inheritProjectContext: false,
	inheritSkills: false,
	systemPrompt: "Explore carefully.",
	source: "builtin",
	filePath: "<builtin:explore>",
	completionGuard: false,
};

describe("foreground executor resume", () => {
	let tempDir: string;
	let originalAgentDir: string | undefined;

	beforeEach(() => {
		tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "subagents-lite-resume-test-"));
		originalAgentDir = process.env.PI_CODING_AGENT_DIR;
		process.env.PI_CODING_AGENT_DIR = path.join(tempDir, "agent");
		spawnMock.mockReset();
		spawnMock.mockImplementation(() => fakeChildProcess());
	});

	afterEach(() => {
		if (originalAgentDir === undefined) delete process.env.PI_CODING_AGENT_DIR;
		else process.env.PI_CODING_AGENT_DIR = originalAgentDir;
		fs.rmSync(tempDir, { recursive: true, force: true });
	});

	it("continues the selected child using its existing session file", async () => {
		const parentSessionFile = path.join(tempDir, "parent.jsonl");
		const childSessionFile = path.join(tempDir, "parent", "oldrun", "run-0", "session.jsonl");
		fs.mkdirSync(path.dirname(childSessionFile), { recursive: true });
		fs.writeFileSync(parentSessionFile, '{"type":"session","version":3,"id":"parent","cwd":"/work"}\n');
		fs.writeFileSync(childSessionFile, '{"type":"session","version":3,"id":"child","cwd":"/work"}\n');

		const state = createState();
		state.foregroundRuns?.set("oldrun", {
			runId: "oldrun",
			mode: "single",
			cwd: tempDir,
			updatedAt: Date.now(),
			children: [{ agent: "explore", index: 0, status: "completed", sessionFile: childSessionFile }],
		});
		const pi = {
			getSessionName: () => undefined,
			events: { on: () => () => {}, emit: () => {} },
		} as unknown as ExtensionAPI;
		const executor = createSubagentExecutor({
			pi,
			state,
			config: { maxSubagentDepth: 1 },
			asyncByDefault: false,
			resumeStrategy: "foreground",
			tempArtifactsDir: path.join(tempDir, "artifacts"),
			getSubagentSessionRoot: () => path.join(tempDir, "sessions"),
			expandTilde: (value: string) => value,
			discoverAgents: () => ({ agents: [agent] }),
		});
		const context = {
			cwd: tempDir,
			hasUI: false,
			model: undefined,
			modelRegistry: { getAvailable: () => [] },
			sessionManager: {
				getSessionFile: () => parentSessionFile,
				getSessionId: () => "parent-session",
				getLeafId: () => "leaf",
			},
		} as unknown as ExtensionContext;

		const result = await executor.execute(
			"tool-call",
			{ action: "resume", id: "oldrun", message: "Continue investigation", acceptance: false, artifacts: false },
			new AbortController().signal,
			undefined,
			context,
		);

		expect(result.content[0]).toMatchObject({ type: "text", text: "continued" });
		expect(result.details?.results[0]?.sessionFile).toBe(childSessionFile);
		expect(result.details?.runId).not.toBe("oldrun");
		expect(state.foregroundRuns?.get(result.details?.runId ?? "")?.children[0]?.sessionFile).toBe(childSessionFile);
		const childArgs = spawnMock.mock.calls[0]?.[1];
		expect(childArgs).toEqual(expect.arrayContaining(["--session", childSessionFile]));
	});
});
