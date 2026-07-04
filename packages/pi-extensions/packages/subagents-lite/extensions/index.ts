import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import type { AgentToolResult } from "@earendil-works/pi-agent-core";
import {
	keyText,
	type ExtensionAPI,
	type ExtensionContext,
	type ToolDefinition,
} from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { Type, type Static } from "typebox";
import { discoverAgents } from "../src/agents/agents.ts";
import { clearLegacyResultAnimationTimer, renderSubagentResult } from "../src/tui/render.ts";
import { createSubagentExecutor, type SubagentParamsLike } from "../src/runs/foreground/subagent-executor.ts";
import { cleanupAllArtifactDirs, getArtifactsDir } from "../src/shared/artifacts.ts";
import { resolveCurrentSessionId } from "../src/shared/session-identity.ts";
import {
	DEFAULT_ARTIFACT_CONFIG,
	type Details,
	type ExtensionConfig,
	type SubagentState,
} from "../src/shared/types.ts";

const ALLOWED_AGENTS = new Set(["explore", "review", "researcher"]);
const RESEARCH_TOOLS = new Set(["exa_search", "exa_contents"]);

const TaskSchema = Type.Object({
	agent: Type.Optional(Type.String({ description: "Agent name: explore, review, or researcher. Defaults to explore." })),
	task: Type.String({ description: "Task for this subagent." }),
	model: Type.Optional(Type.String({ description: "Optional model override for this subagent." })),
});

const SubagentParams = Type.Object({
	action: Type.Optional(Type.String({ enum: ["list"], description: "List available subagents." })),
	agent: Type.Optional(
		Type.String({ description: "Agent name for a single foreground run: explore, review, or researcher. Defaults to explore." }),
	),
	task: Type.Optional(Type.String({ description: "Task for a single foreground run." })),
	tasks: Type.Optional(
		Type.Array(TaskSchema, { minItems: 1, maxItems: 8, description: "Parallel foreground subagent tasks." }),
	),
	concurrency: Type.Optional(
		Type.Integer({ minimum: 1, maximum: 4, description: "Parallel concurrency. Defaults to 2." }),
	),
	model: Type.Optional(Type.String({ description: "Optional model override for all subagents in this call." })),
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
	return name && ALLOWED_AGENTS.has(name) ? name : "explore";
}

function executionParams(params: Static<typeof SubagentParams>): SubagentParamsLike {
	if (params.tasks?.length) {
		return {
			tasks: params.tasks.map((task) => ({
				agent: allowedAgentName(task.agent),
				task: task.task,
				...(task.model ? { model: task.model } : {}),
			})),
			concurrency: params.concurrency,
			context: "fresh",
			async: false,
			clarify: false,
			acceptance: "attested",
			agentScope: "both",
			...(params.model ? { model: params.model } : {}),
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
		...(params.model ? { model: params.model } : {}),
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
		.map((agent) => `- ${agent.name}: ${agent.description}\n  model: ${formatAgentModel(agent)}\n  tools: ${(agent.tools ?? []).join(", ")}`)
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
			"Run foreground-only child Pi subagents with fresh context. Supports single and parallel runs. Available agents: explore, review, researcher. Use action=list to inspect agent descriptions and tool allowlists.",
		promptSnippet:
			"subagent: run focused foreground child agents (explore/review/researcher) with fresh context; supports parallel tasks.",
		promptGuidelines: [
			"Use subagent explore for broad read-only codebase sweeps when you need conclusions without pulling many files into the parent context: locating wiring, call sites, naming variants, related files, or independent search branches.",
			"Do not use explore when you already know the exact file or symbol; use read/grep directly for simple lookups. Explore is read-only and should not edit or make final correctness judgments.",
			"Use subagent review for review, audit, or judgment tasks: checking diffs/plans/solutions for correctness, tests, regressions, and unnecessary complexity. It is also read-only.",
			"Use subagent researcher for external research: current docs, web sources, standards, release notes, ecosystem behavior, benchmarks, GitHub CLI searches, or cloning public repositories into /tmp for deeper inspection.",
			"Do not use Exa directly in the parent; delegate that research to researcher so raw search output and cloned-repository digging stay out of the parent context.",
			"For parallel subagents, launch independent questions together and wait for their results instead of duplicating the same search yourself. Relay only the conclusions that matter.",
			"Subagents always run with fresh context. Give them enough task context, scope, and desired breadth, such as medium or very thorough, because they do not inherit the full conversation.",
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
			if (!params.tasks?.length && !params.task?.trim()) {
				return {
					content: [{ type: "text", text: "Error: provide either task for a single run or tasks for parallel runs." }],
					isError: true,
					details: { mode: "management", context: "fresh", results: [] },
				};
			}
			return executor.execute(id, executionParams(params), signal ?? new AbortController().signal, onUpdate, ctx);
		},
		renderCall(args, theme) {
			if (args.action === "list") return new Text(`${theme.bold("subagent")} list`, 0, 0);
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
