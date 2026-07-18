import type { AgentToolResult } from "@earendil-works/pi-agent-core";
import { Check } from "typebox/value";
import { describe, expect, it } from "vitest";
import {
	applyLiteAgentPolicy,
	collectForegroundRuns,
	latestForegroundRunId,
	SubagentParams,
	withResumeHint,
} from "../extensions/index.js";
import type { Details, SingleResult, SubagentState } from "../src/shared/types.js";

function child(agent: string, sessionFile: string): SingleResult {
	return {
		agent,
		task: "task",
		exitCode: 0,
		usage: { input: 1, output: 1, cacheRead: 0, cacheWrite: 0, cost: 0, turns: 1 },
		finalOutput: "done",
		sessionFile,
	};
}

function toolResult(details: Details): AgentToolResult<Details> {
	return {
		content: [{ type: "text", text: "done" }],
		details,
	};
}

describe("subagents-lite resume support", () => {
	it("disables mutation completion guard for read-only agents", () => {
		expect(
			applyLiteAgentPolicy([
				{ name: "explore", completionGuard: true },
				{ name: "review", completionGuard: true },
				{ name: "researcher", completionGuard: true },
				{ name: "general-purpose", completionGuard: true },
			]),
		).toEqual([
			{ name: "explore", completionGuard: false },
			{ name: "review", completionGuard: false },
			{ name: "researcher", completionGuard: false },
			{ name: "general-purpose", completionGuard: true },
		]);
	});

	it("accepts resume management parameters", () => {
		expect(Check(SubagentParams, { action: "resume", id: "abcd1234", index: 1, message: "Continue" })).toBe(true);
		expect(Check(SubagentParams, { action: "interrupt", id: "abcd1234" })).toBe(false);
	});

	it("restores resumable foreground runs from parent session tool results", () => {
		const entries = [
			{
				type: "message",
				timestamp: "2026-01-01T00:00:00.000Z",
				message: {
					role: "toolResult",
					toolName: "subagent",
					details: {
						mode: "parallel",
						runId: "abcd1234",
						results: [
							{ agent: "explore", exitCode: 0, finalOutput: "first", sessionFile: "/tmp/first.jsonl" },
							{ agent: "review", exitCode: 1, finalOutput: "second", sessionFile: "/tmp/second.jsonl" },
						],
					},
				},
			},
			{
				type: "message",
				message: { role: "toolResult", toolName: "bash", details: {} },
			},
		];

		const runs = collectForegroundRuns(entries, "/work");
		expect(runs.get("abcd1234")).toMatchObject({
			runId: "abcd1234",
			mode: "parallel",
			cwd: "/work",
			children: [
				{ agent: "explore", index: 0, status: "completed", sessionFile: "/tmp/first.jsonl" },
				{ agent: "review", index: 1, status: "failed", sessionFile: "/tmp/second.jsonl" },
			],
		});
	});

	it("selects most recently updated restored run", () => {
		const runs = collectForegroundRuns(
			[
				{
					type: "message",
					timestamp: "2026-01-01T00:00:00.000Z",
					message: {
						role: "toolResult",
						toolName: "subagent",
						details: { mode: "single", runId: "older", results: [{ agent: "explore", exitCode: 0 }] },
					},
				},
				{
					type: "message",
					timestamp: "2026-01-02T00:00:00.000Z",
					message: {
						role: "toolResult",
						toolName: "subagent",
						details: { mode: "single", runId: "newer", results: [{ agent: "review", exitCode: 0 }] },
					},
				},
			],
			"/work",
		);
		const state = { foregroundRuns: runs } as SubagentState;
		expect(latestForegroundRunId(state)).toBe("newer");
	});

	it("adds single and parallel resume instructions to model-visible output", () => {
		const single = withResumeHint(
			toolResult({ mode: "single", runId: "single01", results: [child("explore", "/tmp/single.jsonl")] }),
		);
		expect(single.content[0]).toMatchObject({
			type: "text",
			text: expect.stringContaining('subagent({ action: "resume", id: "single01", message: "<follow-up>" })'),
		});

		const parallel = withResumeHint(
			toolResult({
				mode: "parallel",
				runId: "parallel01",
				results: [child("explore", "/tmp/first.jsonl"), child("review", "/tmp/second.jsonl")],
			}),
		);
		expect(parallel.content[0]).toMatchObject({
			type: "text",
			text: expect.stringContaining("Children: 0=explore, 1=review."),
		});
	});
});
