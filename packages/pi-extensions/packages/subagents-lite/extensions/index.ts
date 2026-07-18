import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import type { AgentToolResult } from "@earendil-works/pi-agent-core";
import type { ExtensionAPI, ToolDefinition } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { type Static, Type } from "typebox";
import { discoverAgents } from "../src/agents/agents.ts";
import { createSubagentExecutor, type SubagentParamsLike } from "../src/runs/foreground/subagent-executor.ts";
import { cleanupAllArtifactDirs, getArtifactsDir } from "../src/shared/artifacts.ts";
import { resolveCurrentSessionId } from "../src/shared/session-identity.ts";
import {
	DEFAULT_ARTIFACT_CONFIG,
	type Details,
	type ExtensionConfig,
	type ForegroundResumeChild,
	type SubagentState,
} from "../src/shared/types.ts";
import { clearLegacyResultAnimationTimer, renderSubagentResult } from "../src/tui/render.ts";

const ALLOWED_AGENTS = new Set(["explore", "review", "researcher", "general-purpose"]);
const RESEARCH_TOOLS = new Set(["exa_search", "exa_contents"]);

const TaskSchema = Type.Object({
	agent: Type.Optional(
		Type.String({ description: "Agent name: explore, review, researcher, or general-purpose. Defaults to explore." }),
	),
	task: Type.String({ description: "Task for this subagent." }),
});

export const SubagentParams = Type.Object({
	action: Type.Optional(
		Type.String({
			enum: ["list", "resume"],
			description: "Management action. Use list to inspect agents or resume to continue a completed child session.",
		}),
	),
	id: Type.Optional(
		Type.String({
			description: "Run ID or unique prefix for action=resume. Omit to resume most recent run.",
		}),
	),
	index: Type.Optional(
		Type.Integer({
			minimum: 0,
			description: "Zero-based child index for action=resume. Required when target run had multiple children.",
		}),
	),
	message: Type.Optional(Type.String({ description: "Follow-up message for action=resume." })),
	agent: Type.Optional(
		Type.String({
			description:
				"Agent name for a single foreground run: explore, review, researcher, or general-purpose. Defaults to explore.",
		}),
	),
	task: Type.Optional(Type.String({ description: "Task for a single foreground run." })),
	tasks: Type.Optional(
		Type.Array(TaskSchema, { minItems: 1, maxItems: 8, description: "Parallel foreground subagent tasks." }),
	),
	concurrency: Type.Optional(
		Type.Integer({ minimum: 1, maximum: 4, description: "Parallel concurrency. Defaults to 2." }),
	),
});

function getSubagentSessionRoot(parentSessionFile: string | null): string {
	if (parentSessionFile) {
		const baseName = path.basename(parentSessionFile, ".jsonl");
		return path.join(path.dirname(parentSessionFile), baseName);
	}
	return fs.mkdtempSync(path.join(os.tmpdir(), "pi-subagent-session-"));
}

function expandTilde(p: string): string {
	return p.startsWith("~/") ? path.join(os.homedir(), p.slice(2)) : p;
}

function asRecord(value: unknown): Record<string, unknown> | undefined {
	return value !== null && typeof value === "object" && !Array.isArray(value)
		? (value as Record<string, unknown>)
		: undefined;
}

function restoredRunTimestamp(
	entry: Record<string, unknown>,
	message: Record<string, unknown>,
	fallback: number,
): number {
	if (typeof message.timestamp === "number" && Number.isFinite(message.timestamp)) return message.timestamp;
	if (typeof entry.timestamp === "string") {
		const parsed = Date.parse(entry.timestamp);
		if (Number.isFinite(parsed)) return parsed;
	}
	return fallback;
}

export function collectForegroundRuns(
	entries: readonly unknown[],
	cwd: string,
): NonNullable<SubagentState["foregroundRuns"]> {
	const runs: NonNullable<SubagentState["foregroundRuns"]> = new Map();
	for (let entryIndex = 0; entryIndex < entries.length; entryIndex++) {
		const entry = asRecord(entries[entryIndex]);
		const message = asRecord(entry?.message);
		const details = asRecord(message?.details);
		if (entry?.type !== "message" || message?.role !== "toolResult" || message.toolName !== "subagent" || !details) {
			continue;
		}

		const runId = typeof details.runId === "string" ? details.runId.trim() : "";
		const mode = details.mode;
		const resultValues = details.results;
		if (
			!runId ||
			(mode !== "single" && mode !== "parallel" && mode !== "chain") ||
			!Array.isArray(resultValues) ||
			resultValues.length === 0
		) {
			continue;
		}

		const updatedAt = restoredRunTimestamp(entry, message, entryIndex);
		const children = resultValues.map((value, index) => {
			const result = asRecord(value);
			if (!result || typeof result.agent !== "string") return undefined;
			const status =
				result.detached === true
					? ("detached" as const)
					: result.interrupted === true
						? ("paused" as const)
						: result.exitCode === 0
							? ("completed" as const)
							: ("failed" as const);
			return {
				agent: result.agent,
				index,
				status,
				updatedAt,
				...(typeof result.exitCode === "number" ? { exitCode: result.exitCode } : {}),
				...(typeof result.finalOutput === "string" ? { finalOutput: result.finalOutput } : {}),
				...(typeof result.sessionFile === "string" ? { sessionFile: result.sessionFile } : {}),
				...(typeof result.transcriptPath === "string" ? { transcriptPath: result.transcriptPath } : {}),
				...(typeof result.transcriptError === "string" ? { transcriptError: result.transcriptError } : {}),
			};
		});
		if (children.some((child) => child === undefined)) continue;

		runs.set(runId, {
			runId,
			mode,
			cwd,
			updatedAt,
			children: children as ForegroundResumeChild[],
		});
	}
	return runs;
}

export function latestForegroundRunId(state: SubagentState): string | undefined {
	let latest: { runId: string; updatedAt: number } | undefined;
	for (const run of state.foregroundRuns?.values() ?? []) {
		if (!latest || run.updatedAt > latest.updatedAt) latest = run;
	}
	return latest?.runId;
}

export function withResumeHint(result: AgentToolResult<Details>): AgentToolResult<Details> {
	const runId = result.details?.runId;
	const results = result.details?.results ?? [];
	if (!runId || results.length === 0) return result;
	const resumable = results.map((child, index) => ({ child, index })).filter(({ child }) => Boolean(child.sessionFile));
	if (resumable.length === 0) return result;

	const targetText =
		results.length === 1
			? `subagent({ action: "resume", id: "${runId}", message: "<follow-up>" })`
			: `subagent({ action: "resume", id: "${runId}", index: <index>, message: "<follow-up>" })`;
	const childrenText =
		results.length > 1
			? ` Children: ${resumable.map(({ child, index }) => `${index}=${child.agent}`).join(", ")}.`
			: "";
	const hint = `Resume handle: ${runId}. Continue with ${targetText}.${childrenText}`;
	const textIndex = result.content.findIndex((item) => item.type === "text");
	if (textIndex === -1) return result;
	const textItem = result.content[textIndex];
	if (!textItem || textItem.type !== "text" || textItem.text.includes(`Resume handle: ${runId}.`)) return result;
	const content = [...result.content];
	content[textIndex] = { ...textItem, text: `${textItem.text}\n\n${hint}` };
	return { ...result, content };
}

function createState(): SubagentState {
	return {
		baseCwd: "",
		currentSessionId: null,
		subagentInProgress: false,
		subagentSpawns: { sessionId: null, count: 0 },
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
		resultFileCoalescer: {
			schedule: () => false,
			clear: () => {},
		},
	};
}

function allowedAgentName(name: string | undefined): string {
	return name ?? "explore";
}

function invalidAgentNames(params: Static<typeof SubagentParams>): string[] {
	const requested = [params.agent, ...(params.tasks ?? []).map((task) => task.agent)];
	return [...new Set(requested.filter((name): name is string => name !== undefined && !ALLOWED_AGENTS.has(name)))];
}

function executionParams(params: Static<typeof SubagentParams>): SubagentParamsLike {
	if (params.tasks?.length) {
		return {
			tasks: params.tasks.map((task) => ({
				agent: allowedAgentName(task.agent),
				task: task.task,
			})),
			concurrency: params.concurrency,
			context: "fresh",
			async: false,
			clarify: false,
			acceptance: "attested",
			agentScope: "both",
		};
	}
	return {
		agent: allowedAgentName(params.agent),
		task: params.task ?? "",
		context: "fresh",
		async: false,
		clarify: false,
		acceptance: "attested",
		agentScope: "both",
	};
}

function configuredAgents(cwd: string) {
	return discoverAgents(cwd, "both").agents.filter((agent) => ALLOWED_AGENTS.has(agent.name));
}

function formatAgentModel(agent: ReturnType<typeof configuredAgents>[number]): string {
	const model = agent.model ?? "default";
	return agent.thinking ? `${model}:${agent.thinking}` : model;
}

function configuredAgentsSummary(cwd: string): string {
	return configuredAgents(cwd)
		.map((agent) => `${agent.name}=${formatAgentModel(agent)}`)
		.join(", ");
}

function listAgentsText(cwd: string): string {
	return configuredAgents(cwd)
		.map(
			(agent) =>
				`- ${agent.name}: ${agent.description}\n  model: ${formatAgentModel(agent)}\n  tools: ${(agent.tools ?? []).join(", ")}`,
		)
		.join("\n");
}

function disableParentResearchTools(pi: ExtensionAPI): boolean {
	const active = pi.getActiveTools();
	const filtered = active.filter((tool) => !RESEARCH_TOOLS.has(tool));
	if (filtered.length === active.length) return false;
	pi.setActiveTools(filtered);
	return true;
}

function hasRunningSubagent(result: AgentToolResult<Details>): boolean {
	return (
		result.details?.progress?.some((entry) => entry.status === "running") ||
		result.details?.results.some((entry) => entry.progress?.status === "running") ||
		false
	);
}

function ensureSubagentResultAnimation(context: { state: Record<string, unknown>; invalidate?: () => void }): void {
	const state = context.state as { subagentResultAnimationTimer?: ReturnType<typeof setInterval>; frame?: number };
	if (state.subagentResultAnimationTimer || typeof context.invalidate !== "function") return;
	state.frame ??= 0;
	state.subagentResultAnimationTimer = setInterval(() => {
		state.frame = ((state.frame ?? 0) + 1) % 10;
		context.invalidate?.();
	}, 80);
}

export default function registerSubagentsLite(pi: ExtensionAPI): void {
	if (process.env.PI_SUBAGENT_CHILD === "1") return;

	cleanupAllArtifactDirs(DEFAULT_ARTIFACT_CONFIG.cleanupDays);
	const state = createState();
	const config: ExtensionConfig = {
		maxSubagentDepth: 1,
		parallel: { concurrency: 2, maxTasks: 8 },
	};
	const executor = createSubagentExecutor({
		pi,
		state,
		config,
		asyncByDefault: false,
		resumeStrategy: "foreground",
		tempArtifactsDir: getArtifactsDir(null),
		getSubagentSessionRoot,
		expandTilde,
		discoverAgents: (cwd, scope) => {
			const result = discoverAgents(cwd, scope);
			return {
				...result,
				agents: result.agents.filter((agent) => ALLOWED_AGENTS.has(agent.name)),
			};
		},
		allowMutatingManagementActions: false,
	});

	pi.on("session_start", (_event, ctx) => {
		state.baseCwd = ctx.cwd;
		state.currentSessionId = resolveCurrentSessionId(ctx.sessionManager);
		state.subagentSpawns = { sessionId: state.currentSessionId, count: 0 };
		state.lastUiContext = ctx;
		state.foregroundRuns = collectForegroundRuns(ctx.sessionManager.getBranch(), ctx.cwd);
		disableParentResearchTools(pi);
		if (ctx.hasUI) ctx.ui.notify(`Subagents: ${configuredAgentsSummary(ctx.cwd)}`, "info");
	});

	pi.on("session_shutdown", () => {
		if (state.poller) clearInterval(state.poller);
		state.poller = null;
		for (const timer of state.cleanupTimers.values()) clearTimeout(timer);
		state.cleanupTimers.clear();
		state.asyncJobs.clear();
		state.foregroundControls.clear();
		state.foregroundRuns?.clear();
	});

	const tool: ToolDefinition<typeof SubagentParams, Details> = {
		name: "subagent",
		label: "Subagent",
		description:
			"Run or resume foreground-only child Pi subagents. New single and parallel runs start with fresh context and return a persistent resume handle. Use action=list to inspect agents or action=resume with id, message, and index for multi-child runs. Available agents: explore, review, researcher, general-purpose.",
		promptSnippet:
			"subagent: run or resume focused foreground child agents (explore/review/researcher/general-purpose); supports fresh single/parallel runs and persistent child sessions.",
		promptGuidelines: [
			"Use subagent explore for broad read-only codebase sweeps when you need conclusions without pulling many files into the parent context: locating wiring, call sites, naming variants, related files, or independent search branches.",
			"Do not use explore when you already know the exact file or symbol; use read/grep directly for simple lookups. Explore is read-only and should not edit or make final correctness judgments.",
			"Use subagent review for review, audit, or judgment tasks: checking diffs/plans/solutions for correctness, tests, regressions, and unnecessary complexity. It is also read-only.",
			"Use subagent researcher for external research: current docs, web sources, standards, release notes, ecosystem behavior, benchmarks, GitHub CLI searches, or cloning public repositories into /tmp for deeper inspection.",
			"Use subagent general-purpose for self-contained multi-step tasks that need file modifications or command execution; it is the only agent that may edit files. Prefer doing edits yourself when they depend on the current conversation.",
			"Do not use Exa directly in the parent; delegate that research to researcher so raw search output and cloned-repository digging stay out of the parent context.",
			"For parallel subagents, launch independent questions together and wait for their results instead of duplicating the same search yourself. Relay only the conclusions that matter.",
			"New subagents run with fresh context. Give them enough task context, scope, and desired breadth because they do not inherit the parent conversation. Use subagent action=resume when follow-up work should continue a returned child session.",
		],
		parameters: SubagentParams,
		executionMode: "sequential",
		async execute(id, params, signal, onUpdate, ctx) {
			if (params.action === "list") {
				return {
					content: [{ type: "text", text: listAgentsText(ctx.cwd) }],
					details: { mode: "management", context: "fresh", results: [] },
				};
			}
			if (params.action === "resume") {
				const runId = params.id?.trim() || latestForegroundRunId(state);
				if (!runId) {
					return {
						content: [
							{ type: "text", text: "Error: no resumable subagent run found. Provide id or start a run first." },
						],
						isError: true,
						details: { mode: "management", context: "fresh", results: [] },
					};
				}
				const message = params.message?.trim();
				if (!message) {
					return {
						content: [{ type: "text", text: "Error: action=resume requires message." }],
						isError: true,
						details: { mode: "management", context: "fresh", results: [] },
					};
				}
				const resumed = await executor.execute(
					id,
					{
						action: "resume",
						id: runId,
						index: params.index,
						message,
						context: "fresh",
						async: false,
						clarify: false,
						acceptance: "attested",
						agentScope: "both",
					},
					signal ?? new AbortController().signal,
					onUpdate,
					ctx,
				);
				return withResumeHint(resumed);
			}
			const unknownAgents = invalidAgentNames(params);
			if (unknownAgents.length > 0) {
				return {
					content: [
						{
							type: "text",
							text: `Error: unknown agent name(s): ${unknownAgents.join(", ")}. Available agents: ${[...ALLOWED_AGENTS].join(", ")}.`,
						},
					],
					isError: true,
					details: { mode: "management", context: "fresh", results: [] },
				};
			}
			if (!params.tasks?.length && !params.task?.trim()) {
				return {
					content: [{ type: "text", text: "Error: provide either task for a single run or tasks for parallel runs." }],
					isError: true,
					details: { mode: "management", context: "fresh", results: [] },
				};
			}
			const result = await executor.execute(
				id,
				executionParams(params),
				signal ?? new AbortController().signal,
				onUpdate,
				ctx,
			);
			return withResumeHint(result);
		},
		renderCall(args, theme) {
			if (args.action === "list") return new Text(`${theme.bold("subagent")} list`, 0, 0);
			if (args.action === "resume") {
				const target = args.id ? ` ${args.id}${args.index !== undefined ? `:${args.index}` : ""}` : " latest";
				return new Text(`${theme.bold("subagent")} resume${target}`, 0, 0);
			}
			if (args.tasks?.length) return new Text(`${theme.bold("subagent")} parallel (${args.tasks.length})`, 0, 0);
			return new Text(`${theme.bold("subagent")} ${args.agent ?? "explore"}`, 0, 0);
		},
		renderResult(result, options, theme, context) {
			if (hasRunningSubagent(result)) ensureSubagentResultAnimation(context);
			else clearLegacyResultAnimationTimer(context);
			const frame = (context.state as { frame?: number }).frame ?? 0;
			return renderSubagentResult(result, options, theme, frame);
		},
	};

	pi.registerTool(tool);
}
