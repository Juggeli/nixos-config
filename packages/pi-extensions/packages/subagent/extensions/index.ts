/**
 * Subagent Tool — Delegate tasks to in-process agent sessions via the SDK.
 *
 * Supports single and parallel execution modes.
 * Sessions are kept alive in memory for resume within parent session lifetime.
 */

import * as os from "node:os";
import type { Message } from "@mariozechner/pi-ai";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { type AgentSession, type AgentSessionEvent, getMarkdownTheme } from "@mariozechner/pi-coding-agent";
import { Container, Markdown, Spacer, Text } from "@mariozechner/pi-tui";
import { Type } from "@sinclair/typebox";
import { getAgent, listAgents } from "./agents/index.js";
import { resumeAgent, runAgent } from "./executor.js";
import { clearModelOverride, loadModelOverrides, setModelOverride } from "./model-config.js";
import type { DisplayItem, OnUpdateCallback, SingleResult, SubagentDetails, UsageStats } from "./types.js";
import {
	ACTIVITY_WINDOW_SIZE,
	COLLAPSED_ITEM_COUNT,
	LIVE_TEXT_WINDOW_SIZE,
	LIVE_TOOL_WINDOW_SIZE,
	emptyUsage,
	MAX_PARALLEL_TASKS,
	MAX_CONCURRENCY,
} from "./types.js";

// =============================================================================
// Session tracking (in-memory, keyed by session ID)
// =============================================================================

const liveSessions = new Map<string, AgentSession>();
let sessionCounter = 0;

function trackSession(session: AgentSession): string {
	const id = `sa-${++sessionCounter}`;
	liveSessions.set(id, session);
	return id;
}

// =============================================================================
// Utilities
// =============================================================================

function formatTokens(count: number): string {
	if (count < 1000) return count.toString();
	if (count < 10000) return `${(count / 1000).toFixed(1)}k`;
	if (count < 1000000) return `${Math.round(count / 1000)}k`;
	return `${(count / 1000000).toFixed(1)}M`;
}

function formatUsage(usage: UsageStats, options?: { includeContext?: boolean }): string {
	const parts: string[] = [];
	if (usage.turns) parts.push(`${usage.turns} turn${usage.turns > 1 ? "s" : ""}`);
	if (usage.input) parts.push(`↑${formatTokens(usage.input)}`);
	if (usage.output) parts.push(`↓${formatTokens(usage.output)}`);
	if (usage.cacheRead) parts.push(`R${formatTokens(usage.cacheRead)}`);
	if (usage.cacheWrite) parts.push(`W${formatTokens(usage.cacheWrite)}`);
	if (usage.cost) parts.push(`$${usage.cost.toFixed(4)}`);
	if (options?.includeContext !== false && usage.contextTokens) parts.push(`ctx:${formatTokens(usage.contextTokens)}`);
	return parts.join(" ");
}

function getFinalOutput(messages: Message[]): string {
	for (let i = messages.length - 1; i >= 0; i--) {
		const msg = messages[i];
		if (msg.role === "assistant") {
			for (const part of msg.content) {
				if (part.type === "text") return part.text;
			}
		}
	}
	return "";
}

function formatToolCall(
	toolName: string,
	args: Record<string, unknown>,
	themeFg: (color: any, text: string) => string,
): string {
	const shortenPath = (p: string) => {
		const home = os.homedir();
		return p.startsWith(home) ? `~${p.slice(home.length)}` : p;
	};

	switch (toolName) {
		case "bash": {
			const command = (args.command as string) || "...";
			const preview = command.length > 60 ? `${command.slice(0, 60)}...` : command;
			return themeFg("muted", "$ ") + themeFg("toolOutput", preview);
		}
		case "read": {
			const rawPath = (args.file_path || args.path || "...") as string;
			const filePath = shortenPath(rawPath);
			const offset = args.offset as number | undefined;
			const limit = args.limit as number | undefined;
			let text = themeFg("accent", filePath);
			if (offset !== undefined || limit !== undefined) {
				const startLine = offset ?? 1;
				const endLine = limit !== undefined ? startLine + limit - 1 : "";
				text += themeFg("warning", `:${startLine}${endLine ? `-${endLine}` : ""}`);
			}
			return themeFg("muted", "read ") + text;
		}
		case "write": {
			const rawPath = (args.file_path || args.path || "...") as string;
			const filePath = shortenPath(rawPath);
			const content = (args.content || "") as string;
			const lines = content.split("\n").length;
			let text = themeFg("muted", "write ") + themeFg("accent", filePath);
			if (lines > 1) text += themeFg("dim", ` (${lines} lines)`);
			return text;
		}
		case "edit": {
			const rawPath = (args.file_path || args.path || "...") as string;
			return themeFg("muted", "edit ") + themeFg("accent", shortenPath(rawPath));
		}
		case "ls": {
			const rawPath = (args.path || ".") as string;
			return themeFg("muted", "ls ") + themeFg("accent", shortenPath(rawPath));
		}
		case "find": {
			const pattern = (args.pattern || "*") as string;
			const rawPath = (args.path || ".") as string;
			return themeFg("muted", "find ") + themeFg("accent", pattern) + themeFg("dim", ` in ${shortenPath(rawPath)}`);
		}
		case "grep": {
			const pattern = (args.pattern || "") as string;
			const rawPath = (args.path || ".") as string;
			return (
				themeFg("muted", "grep ") +
				themeFg("accent", `/${pattern}/`) +
				themeFg("dim", ` in ${shortenPath(rawPath)}`)
			);
		}
		default: {
			const argsStr = JSON.stringify(args);
			const preview = argsStr.length > 50 ? `${argsStr.slice(0, 50)}...` : argsStr;
			return themeFg("accent", toolName) + themeFg("dim", ` ${preview}`);
		}
	}
}

function formatToolCallPlain(toolName: string, args: Record<string, unknown>): string {
	return formatToolCall(toolName, args, (_color, text) => text);
}

function formatTaskPreview(task: string, maxLines = 2, maxLineLength = 72): string {
	const rawLines = task.replace(/\r/g, "").split("\n");
	const nonEmptyLines = rawLines.map((line) => line.trim()).filter(Boolean);
	if (nonEmptyLines.length === 0) return "";

	const lines = nonEmptyLines.slice(0, maxLines).map((line) =>
		line.length > maxLineLength ? `${line.slice(0, maxLineLength - 3)}...` : line,
	);

	if (nonEmptyLines.length > maxLines) {
		lines.push("...");
	}

	return lines.join("\n");
}

function getDisplayItems(messages: Message[]): DisplayItem[] {
	const items: DisplayItem[] = [];
	for (const msg of messages) {
		if (msg.role === "assistant") {
			for (const part of msg.content) {
				if (part.type === "text") items.push({ type: "text", text: part.text });
				else if (part.type === "toolCall") items.push({ type: "toolCall", name: part.name, args: part.arguments });
			}
		}
	}
	return items;
}

function appendLiveText(current: string | undefined, delta: string, maxChars = LIVE_TEXT_WINDOW_SIZE): string {
	return ((current || "") + delta).slice(-maxChars);
}

function toPreviewLines(text: string | undefined, maxLines: number, maxLineLength = 96): string[] {
	if (!text) return [];

	const chunks: string[] = [];
	for (const rawLine of text.replace(/\r/g, "").split("\n")) {
		const line = rawLine.trim();
		if (!line) continue;
		for (let i = 0; i < line.length; i += maxLineLength) {
			chunks.push(line.slice(i, i + maxLineLength));
		}
	}

	if (chunks.length === 0) {
		const line = text.trim();
		if (!line) return [];
		for (let i = 0; i < line.length; i += maxLineLength) {
			chunks.push(line.slice(i, i + maxLineLength));
		}
	}

	return chunks.slice(-maxLines);
}

function setActivityBlock(result: SingleResult, key: string, texts: string[]): void {
	const normalized = texts.map((text) => text.trim()).filter(Boolean);
	if (normalized.length === 0) return;
	if (!result.recentActivityLines) result.recentActivityLines = [];

	const lines = result.recentActivityLines;
	clearActivityBlock(result, key);
	normalized.forEach((text, index) => {
		lines.push({ key: normalized.length === 1 ? key : `${key}:${index}`, text });
	});
	if (lines.length > ACTIVITY_WINDOW_SIZE) {
		lines.splice(0, lines.length - ACTIVITY_WINDOW_SIZE);
	}
}

function clearActivityBlock(result: SingleResult, key: string): void {
	if (!result.recentActivityLines) return;
	for (let i = result.recentActivityLines.length - 1; i >= 0; i--) {
		const lineKey = result.recentActivityLines[i].key;
		if (lineKey === key || lineKey.startsWith(`${key}:`)) {
			result.recentActivityLines.splice(i, 1);
		}
	}
}

function upsertActivityLine(result: SingleResult, key: string, text: string): void {
	setActivityBlock(result, key, [text]);
}

export function buildLivePreviewText(result: SingleResult): string {
	if (result.compactLivePreview) {
		const toolLine =
			result.recentActivityLines
				?.slice()
				.reverse()
				.find((line) => line.key === "tool")?.text ||
			(result.lastToolCall ? `→ ${formatToolCallPlain(result.lastToolCall.name, result.lastToolCall.args)}` : undefined);
		if (toolLine) return toolLine;
	}

	const lines = result.recentActivityLines?.map((line) => line.text).slice(-5) || [];
	if (lines.length > 0) {
		return lines.join("\n");
	}

	if (result.errorMessage) return result.errorMessage;
	if (result.currentActivity) return result.currentActivity;
	return result.exitCode === -1 ? "(running...)" : "(no output)";
}

async function mapWithConcurrencyLimit<TIn, TOut>(
	items: TIn[],
	concurrency: number,
	fn: (item: TIn, index: number) => Promise<TOut>,
): Promise<TOut[]> {
	if (items.length === 0) return [];
	const limit = Math.max(1, Math.min(concurrency, items.length));
	const results: TOut[] = new Array(items.length);
	let nextIndex = 0;
	const workers = new Array(limit).fill(null).map(async () => {
		while (true) {
			const current = nextIndex++;
			if (current >= items.length) return;
			results[current] = await fn(items[current], current);
		}
	});
	await Promise.all(workers);
	return results;
}

// =============================================================================
// Schema
// =============================================================================

const TaskItem = Type.Object({
	agent: Type.String({ description: "Name of the agent to invoke" }),
	task: Type.String({ description: "Task to delegate" }),
	session: Type.Optional(Type.String({ description: "Session ID to resume (returned from previous call)" })),
});

const SubagentParamsSchema = Type.Object({
	agent: Type.Optional(Type.String({ description: "Agent name (single mode). Omit to list available agents." })),
	task: Type.Optional(Type.String({ description: "Task (single mode). Required with agent." })),
	session: Type.Optional(Type.String({ description: "Session ID to resume (returned from previous call)" })),
	tasks: Type.Optional(Type.Array(TaskItem, { description: "Parallel tasks" })),
});

// =============================================================================
// Extension
// =============================================================================

export default function (pi: ExtensionAPI) {
	// Skip registration if running as a subagent (prevent fork bomb — safety net)
	if (process.env.PI_SUBAGENT) {
		return;
	}

	// =========================================================================
	// /agent-models command
	// =========================================================================

	const allAgentConfigs = listAgents();
	let cachedModelRegistry: import("@mariozechner/pi-coding-agent").ModelRegistry | undefined;
	pi.registerCommand("agent-models", {
		description: "View or set subagent model overrides",
		getArgumentCompletions: (prefix: string) => {
			// If prefix contains a space, we're completing the second arg (model)
			const spaceIdx = prefix.indexOf(" ");
			if (spaceIdx !== -1) {
				if (!cachedModelRegistry) return null;
				const modelPrefix = prefix.substring(spaceIdx + 1).toLowerCase();
				const models = cachedModelRegistry.getAvailable();
				return models
					.filter((m) => `${m.provider}/${m.id}`.toLowerCase().startsWith(modelPrefix))
					.slice(0, 50)
					.map((m) => ({
						value: `${prefix.substring(0, spaceIdx)} ${m.provider}/${m.id}`,
						label: `${m.provider}/${m.id}`,
						description: m.name || "",
					}));
			}
			// First arg: agent names
			return allAgentConfigs
				.filter((a) => a.name.toLowerCase().startsWith(prefix.toLowerCase()))
				.map((a) => ({
					value: a.name,
					label: a.name,
					description: a.description,
				}));
		},
		handler: async (args, ctx) => {
			const parts = args.trim().split(/\s+/);
			const agentName = parts[0] || "";
			const modelArg = parts.slice(1).join(" ");

			// No args: list all agents with their models
			if (!agentName) {
				const overrides = loadModelOverrides();
				const lines = allAgentConfigs.map((a) => {
					const override = overrides[a.name];
					const defaultModel = a.model || "(parent model)";
					if (override) {
						return `- ${a.name}: ${override} (override, default: ${defaultModel})`;
					}
					return `- ${a.name}: ${defaultModel}`;
				});
				ctx.ui.notify(`Subagent models:\n\n${lines.join("\n")}`, "info");
				return;
			}

			// Validate agent name
			const agent = allAgentConfigs.find((a) => a.name === agentName);
			if (!agent) {
				const available = allAgentConfigs.map((a) => a.name).join(", ");
				ctx.ui.notify(`Unknown agent: "${agentName}". Available: ${available}`, "error");
				return;
			}

			// --reset: clear override
			if (modelArg === "--reset") {
				clearModelOverride(agentName);
				const defaultModel = agent.model || "(parent model)";
				ctx.ui.notify(`Reset ${agentName} to default: ${defaultModel}`, "info");
				return;
			}

			// No model arg: show current for this agent
			if (!modelArg) {
				const overrides = loadModelOverrides();
				const override = overrides[agentName];
				const defaultModel = agent.model || "(parent model)";
				if (override) {
					ctx.ui.notify(`${agentName}: ${override} (override, default: ${defaultModel})`, "info");
				} else {
					ctx.ui.notify(`${agentName}: ${defaultModel} (default)`, "info");
				}
				return;
			}

			// Set override
			setModelOverride(agentName, modelArg);
			ctx.ui.notify(`Set ${agentName} model to: ${modelArg}`, "info");
		},
	});

	// Cache model registry as early as possible for completions
	pi.on("session_start", async (_event, ctx) => {
		cachedModelRegistry = ctx.modelRegistry;
	});

	pi.on("turn_start", async (_event, ctx) => {
		if (!cachedModelRegistry) cachedModelRegistry = ctx.modelRegistry;
	});

	// =========================================================================
	// Subagent tool
	// =========================================================================

	pi.registerTool({
		name: "subagent",
		label: "Subagent",
		description: [
			"Delegate tasks to specialized agents with isolated in-process sessions.",
			"",
			"Modes:",
			"  • Single: agent + task",
			"  • Parallel: tasks[] (concurrent)",
			"",
			"Resume: pass session ID (from previous result) to continue a conversation.",
			"",
			"Built-in agents: explore, librarian.",
		].join("\n"),
		promptSnippet: "Use subagent for focused investigation: explore for this repo, librarian for external docs/code",
		promptGuidelines: [
			"Use subagent for self-contained investigation or evidence gathering, not for trivial work that is faster to do directly.",
			"Treat explore and librarian as read-only peer tools for research, not as fallback after you have already done the same search yourself.",
			"Use the explore agent for read-only codebase search, architecture tracing, finding files, symbols, usages, and git history in the current repository.",
			"Use direct tools instead of explore when you already know the exact file or exact command you need and delegation would add overhead.",
			"Use the librarian agent for external libraries, frameworks, API docs, upstream source code, GitHub issues, and evidence-backed research outside the local repo.",
			"Prefer tasks[] when you have multiple independent search angles or questions to ask at once.",
			"Use tasks[] to gather several independent findings in one subagent call instead of making multiple separate subagent calls.",
			"Use session to resume an existing subagent conversation for follow-up questions, refinements, or retrying with the same context instead of starting over.",
			"Write delegated tasks as concrete, scoped requests with the question to answer or evidence to gather.",
			"Do not use subagent for edits or file writes; these agents are for investigation and research.",
		],
		parameters: SubagentParamsSchema,

		async execute(_toolCallId, params, signal, onUpdate, ctx) {
			const agents = listAgents("subagent");

			// ─── Determine execution mode ─────────────────────────────

			if (agents.length === 0) {
				return {
					content: [{ type: "text", text: "Error: No agents configured." }],
					details: { mode: "single", results: [] } as SubagentDetails,
					isError: true,
				};
			}

			const hasTasks = (params.tasks?.length ?? 0) > 0;
			const hasSingle = Boolean(params.agent && params.task);
			const modeCount = Number(hasTasks) + Number(hasSingle);

			const makeDetails =
				(mode: SubagentDetails["mode"]) =>
				(results: SingleResult[]): SubagentDetails => ({
					mode,
					results,
				});

			// If no mode specified, return a usage error instead of a discovery result.
			if (modeCount === 0) {
				const available = agents.map((a) => `"${a.name}"`).join(", ") || "none";
				return {
					content: [
						{
							type: "text",
							text: `Missing parameters. Use agent + task, or tasks[]. Available: ${available}`,
						},
					],
					details: makeDetails("single")([]),
					isError: true,
				};
			}

			if (modeCount !== 1) {
				const available = agents.map((a) => `"${a.name}"`).join(", ") || "none";
				return {
					content: [
						{
							type: "text",
							text: `Error: Provide exactly one mode (single/parallel). Available: ${available}`,
						},
					],
					details: makeDetails("single")([]),
					isError: true,
				};
			}

			// ─── Helper: run single agent ─────────────────────────────

			const runSingle = async (
				agentName: string,
				task: string,
				sessionId: string | undefined,
				taskSignal: AbortSignal | undefined,
				taskOnUpdate: OnUpdateCallback | undefined,
				taskMakeDetails: (results: SingleResult[]) => SubagentDetails,
			): Promise<SingleResult> => {
				const agentConfig = getAgent(agentName);
				if (!agentConfig) {
					const available = agents.map((a) => `"${a.name}"`).join(", ") || "none";
					return {
						agent: agentName,
						task,
						exitCode: 1,
						messages: [],
						usage: emptyUsage(),
						errorMessage: `Unknown agent: "${agentName}". Available: ${available}`,
					};
				}

				const currentResult: SingleResult = {
					agent: agentName,
					task,
					exitCode: -1,
					messages: [],
					usage: emptyUsage(),
					compactLivePreview: agentConfig.compactLivePreview,
				};

				const emitUpdate = () => {
					if (taskOnUpdate) {
						taskOnUpdate({
							content: [{ type: "text", text: buildLivePreviewText(currentResult) }],
							details: taskMakeDetails([currentResult]),
						});
					}
				};
				// Check for session resume
				if (sessionId && !liveSessions.has(sessionId)) {
					return {
						agent: agentName,
						task,
						exitCode: 1,
						messages: [],
						usage: emptyUsage(),
						errorMessage: `Session not found: "${sessionId}". It may have expired or the ID is incorrect.`,
					};
				}
				const existingSession = sessionId ? liveSessions.get(sessionId) : undefined;

				try {
					let resultData: { result: import("./types.js").TaskResult; session?: AgentSession };

					if (existingSession) {
						// Resume existing session
						currentResult.currentActivity = "Resuming...";
						currentResult.sessionId = sessionId;
						emitUpdate();

						const onEvent = (event: AgentSessionEvent) => {
							handleAgentEvent(event, currentResult, emitUpdate);
						};

						const taskResult = await resumeAgent(existingSession, task, taskSignal, onEvent);
						resultData = { result: taskResult };
						// Session is already tracked
					} else {
						// New session
						currentResult.currentActivity = "Starting...";
						emitUpdate();

						const onEvent = (event: AgentSessionEvent) => {
							handleAgentEvent(event, currentResult, emitUpdate);
						};

						const { result, session } = await runAgent(agentConfig, task, ctx, taskSignal, onEvent);
						const newSessionId = trackSession(session);
						currentResult.sessionId = newSessionId;
						resultData = { result };
					}

					currentResult.exitCode = resultData.result.exitCode;
					currentResult.messages = resultData.result.messages;
					currentResult.usage = resultData.result.usage;
					currentResult.errorMessage = resultData.result.errorMessage;
					currentResult.currentActivity = "Finished";
					emitUpdate();
					return currentResult;
				} catch (error) {
					currentResult.exitCode = 1;
					currentResult.errorMessage = error instanceof Error ? error.message : String(error);
					return currentResult;
				}
			};

			// ─── Parallel mode ────────────────────────────────────────

			if (params.tasks && params.tasks.length > 0) {
				if (params.tasks.length > MAX_PARALLEL_TASKS) {
					return {
						content: [{ type: "text", text: `Error: Max ${MAX_PARALLEL_TASKS} parallel tasks` }],
						details: makeDetails("parallel")([]),
						isError: true,
					};
				}

				const allResults: SingleResult[] = new Array(params.tasks.length);
				for (let i = 0; i < params.tasks.length; i++) {
					allResults[i] = {
						agent: params.tasks[i].agent,
						task: params.tasks[i].task,
						exitCode: -1,
						messages: [],
						usage: emptyUsage(),
					};
				}

				const emitParallelUpdate = () => {
					if (onUpdate) {
						const running = allResults.filter((r) => r.exitCode === -1).length;
						const done = allResults.filter((r) => r.exitCode !== -1).length;
						onUpdate({
							content: [
								{ type: "text", text: `Parallel: ${done}/${allResults.length} done, ${running} running` },
							],
							details: makeDetails("parallel")([...allResults]),
						});
					}
				};

				const results = await mapWithConcurrencyLimit(params.tasks, MAX_CONCURRENCY, async (t, index) => {
					const result = await runSingle(
						t.agent,
						t.task,
						t.session,
						signal,
						(partial) => {
							if (partial.details?.results[0]) {
								allResults[index] = partial.details.results[0];
								emitParallelUpdate();
							}
						},
						makeDetails("parallel"),
					);
					allResults[index] = result;
					emitParallelUpdate();
					return result;
				});

				const successCount = results.filter((r) => r.exitCode === 0).length;
				const summaries = results.map((r) => {
					const output = getFinalOutput(r.messages).slice(0, 100);
					return `[${r.agent}] ${r.exitCode === 0 ? "✓" : "✗"} ${output}${output.length >= 100 ? "..." : ""}`;
				});

				return {
					content: [
						{
							type: "text",
							text: `Parallel: ${successCount}/${results.length} succeeded\n\n${summaries.join("\n")}`,
						},
					],
					details: makeDetails("parallel")(results),
				};
			}

			// ─── Single mode ──────────────────────────────────────────

			if (params.agent && params.task) {
				const result = await runSingle(
					params.agent,
					params.task,
					params.session,
					signal,
					onUpdate,
					makeDetails("single"),
				);

				if (result.exitCode !== 0) {
					const errorMsg = result.errorMessage || getFinalOutput(result.messages) || "(no output)";
					return {
						content: [{ type: "text", text: `Agent failed: ${errorMsg}` }],
						details: makeDetails("single")([result]),
						isError: true,
					};
				}

				const outputText = getFinalOutput(result.messages) || "(no output)";
				const sessionInfo = result.sessionId ? `\n\nSession: ${result.sessionId}` : "";
				return {
					content: [{ type: "text", text: outputText + sessionInfo }],
					details: makeDetails("single")([result]),
				};
			}

			const available = agents.map((a) => `"${a.name}"`).join(", ") || "none";
			return {
				content: [{ type: "text", text: `Invalid parameters. Available: ${available}` }],
				details: makeDetails("single")([]),
				isError: true,
			};
		},

		renderCall(args, theme) {
			const isResume = args.session || args.tasks?.some((t: any) => t.session);

			if (args.tasks && args.tasks.length > 0) {
				let text =
					theme.fg("toolTitle", theme.bold("subagent ")) + theme.fg("accent", `parallel (${args.tasks.length})`);
				if (isResume) text += theme.fg("warning", " [resume]");
				for (const t of args.tasks.slice(0, 2)) {
					text += `\n  ${theme.fg("accent", t.agent)}${t.session ? theme.fg("dim", " (resume)") : ""}`;
				}
				if (args.tasks.length > 2) text += `\n  ${theme.fg("muted", `...+${args.tasks.length - 2}`)}`;
				return new Text(text, 0, 0);
			}

			const agent = args.agent || "...";
			const agentConfig = args.agent ? getAgent(args.agent) : undefined;
			let text = theme.fg("toolTitle", theme.bold("subagent ")) + theme.fg("accent", agent);
			if (isResume) text += theme.fg("warning", " [resume]");
			if (args.task && !agentConfig?.compactLivePreview) {
				const preview = formatTaskPreview(args.task);
				if (preview) {
					text += `\n  ${theme.fg("dim", preview).replace(/\n/g, "\n  ")}`;
				}
			}
			return new Text(text, 0, 0);
		},

		renderResult(result, { expanded, isPartial }, theme) {
			const details = result.details as SubagentDetails | undefined;

			if (!details || details.results.length === 0) {
				const text = result.content[0];
				return new Text(text?.type === "text" ? text.text : "(no output)", 0, 0);
			}

			const mdTheme = getMarkdownTheme();

			const renderDisplayItems = (items: DisplayItem[], limit?: number) => {
				const toShow = limit ? items.slice(-limit) : items;
				const skipped = limit && items.length > limit ? items.length - limit : 0;
				let text = "";
				if (skipped > 0) text += theme.fg("muted", `... ${skipped} earlier items\n`);
				for (const item of toShow) {
					if (item.type === "text") {
						const preview = expanded ? item.text : item.text.split("\n").slice(0, 3).join("\n");
						text += `${theme.fg("toolOutput", preview)}\n`;
					} else {
						text += `${theme.fg("muted", "→ ") + formatToolCall(item.name, item.args, theme.fg.bind(theme))}\n`;
					}
				}
				return text.trimEnd();
			};

			if (details.mode === "single" && details.results.length === 1) {
				const r = details.results[0];
				const isError = r.exitCode !== 0;
				const icon = isError ? theme.fg("error", "✗") : theme.fg("success", "✓");
				const displayItems = getDisplayItems(r.messages);
				const finalOutput = getFinalOutput(r.messages);

				if (expanded && !isPartial) {
					const container = new Container();
					let header = `${icon} ${theme.fg("toolTitle", theme.bold(r.agent))}`;
					if (r.sessionId) header += theme.fg("dim", ` [${r.sessionId}]`);
					if (isError && r.errorMessage) header += ` ${theme.fg("error", `[error]`)}`;
					container.addChild(new Text(header, 0, 0));
					if (isError && r.errorMessage)
						container.addChild(new Text(theme.fg("error", `Error: ${r.errorMessage}`), 0, 0));
					container.addChild(new Spacer(1));
					container.addChild(new Text(theme.fg("muted", "─── Task ───"), 0, 0));
					container.addChild(new Text(theme.fg("dim", r.task), 0, 0));
					container.addChild(new Spacer(1));
					container.addChild(new Text(theme.fg("muted", "─── Output ───"), 0, 0));
					if (displayItems.length === 0 && !finalOutput) {
						container.addChild(new Text(theme.fg("muted", "(no output)"), 0, 0));
					} else {
						for (const item of displayItems) {
							if (item.type === "toolCall")
								container.addChild(
									new Text(
										theme.fg("muted", "→ ") + formatToolCall(item.name, item.args, theme.fg.bind(theme)),
										0,
										0,
									),
								);
						}
						if (finalOutput) {
							container.addChild(new Spacer(1));
							container.addChild(new Markdown(finalOutput.trim(), 0, 0, mdTheme));
						}
					}
					const usageStr = formatUsage(r.usage);
					if (usageStr) {
						container.addChild(new Spacer(1));
						container.addChild(new Text(theme.fg("dim", usageStr), 0, 0));
					}
					return container;
				}

				if (isPartial) {
					const previewText = buildLivePreviewText(r);
					return new Text(previewText, 0, 0);
				}

				const usageStr = formatUsage(r.usage);
				let text = "";
				if (isError && r.errorMessage) {
					text += theme.fg("error", `✗ ${r.errorMessage}`);
				} else if (r.compactLivePreview && finalOutput) {
					const lines = finalOutput.trim().split("\n");
					const preview = lines.slice(0, 6).join("\n");
					text += theme.fg("toolOutput", preview);
					if (lines.length > 6) {
						text += `\n${theme.fg("muted", "(Ctrl+O to expand)")}`;
					}
				} else if (displayItems.length > 0) {
					text += renderDisplayItems(displayItems, COLLAPSED_ITEM_COUNT);
					if (displayItems.length > COLLAPSED_ITEM_COUNT) {
						text += `\n${theme.fg("muted", "(Ctrl+O to expand)")}`;
					}
				} else if (finalOutput) {
					const preview = finalOutput.trim().split("\n").slice(0, COLLAPSED_ITEM_COUNT).join("\n");
					text += theme.fg("toolOutput", preview);
					if (finalOutput.trim().split("\n").length > COLLAPSED_ITEM_COUNT) {
						text += `\n${theme.fg("muted", "(Ctrl+O to expand)")}`;
					}
				} else {
					text += theme.fg("muted", "(no output)");
				}
				text += `\n${isError ? theme.fg("error", "✗") : theme.fg("success", "✓")}`;
				if (usageStr) text += ` ${theme.fg("dim", usageStr)}`;
				return new Text(text.trimEnd(), 0, 0);
			}

			const aggregateUsage = (results: SingleResult[]) => {
				const total: UsageStats = emptyUsage();
				for (const r of results) {
					total.input += r.usage.input;
					total.output += r.usage.output;
					total.cacheRead += r.usage.cacheRead;
					total.cacheWrite += r.usage.cacheWrite;
					total.cost += r.usage.cost;
					total.turns += r.usage.turns;
					total.contextTokens += r.usage.contextTokens;
				}
				return total;
			};

			if (details.mode === "parallel") {
				const running = details.results.filter((r) => r.exitCode === -1).length;
				const successCount = details.results.filter((r) => r.exitCode === 0).length;
				const failCount = details.results.filter((r) => r.exitCode > 0).length;
				const isRunning = running > 0;
				const icon = isRunning
					? theme.fg("warning", "⏳")
					: failCount > 0
						? theme.fg("warning", "◐")
						: theme.fg("success", "✓");
				const status = isRunning
					? `${successCount + failCount}/${details.results.length} done, ${running} running`
					: `${successCount}/${details.results.length} tasks`;

				if (expanded && !isRunning) {
					const container = new Container();
					container.addChild(
						new Text(
							`${icon} ${theme.fg("toolTitle", theme.bold("parallel "))}${theme.fg("accent", status)}`,
							0,
							0,
						),
					);

					for (const r of details.results) {
						const rIcon = r.exitCode === 0 ? theme.fg("success", "✓") : theme.fg("error", "✗");
						const displayItems = getDisplayItems(r.messages);
						const finalOutput = getFinalOutput(r.messages);

						container.addChild(new Spacer(1));
						container.addChild(
							new Text(`${theme.fg("muted", "─── ") + theme.fg("accent", r.agent)} ${rIcon}`, 0, 0),
						);
						container.addChild(new Text(theme.fg("muted", "Task: ") + theme.fg("dim", r.task), 0, 0));

						for (const item of displayItems) {
							if (item.type === "toolCall") {
								container.addChild(
									new Text(
										theme.fg("muted", "→ ") + formatToolCall(item.name, item.args, theme.fg.bind(theme)),
										0,
										0,
									),
								);
							}
						}

						if (finalOutput) {
							container.addChild(new Spacer(1));
							container.addChild(new Markdown(finalOutput.trim(), 0, 0, mdTheme));
						}

						const taskUsage = formatUsage(r.usage);
						if (taskUsage) container.addChild(new Text(theme.fg("dim", taskUsage), 0, 0));
					}

					const totalUsage = formatUsage(aggregateUsage(details.results), { includeContext: false });
					if (totalUsage) {
						container.addChild(new Spacer(1));
						container.addChild(new Text(theme.fg("dim", `Total: ${totalUsage}`), 0, 0));
					}
					return container;
				}

				// Collapsed view (or still running)
				let text = `${icon} ${theme.fg("toolTitle", theme.bold("parallel "))}${theme.fg("accent", status)}`;
				for (const r of details.results) {
					const rIcon =
						r.exitCode === -1
							? theme.fg("warning", "⏳")
							: r.exitCode === 0
								? theme.fg("success", "✓")
								: theme.fg("error", "✗");
					const displayItems = getDisplayItems(r.messages);
					text += `\n\n${theme.fg("muted", "─── ")}${theme.fg("accent", r.agent)} ${rIcon}`;
					if (r.exitCode === -1) text += `\n${buildLivePreviewText(r)}`;
					else if (displayItems.length === 0) text += `\n${theme.fg("muted", "(no output)")}`;
					else text += `\n${renderDisplayItems(displayItems, 5)}`;
				}
				const totalUsage = formatUsage(aggregateUsage(details.results), { includeContext: false });
				if (totalUsage) text += `\n${theme.fg("dim", `Total: ${totalUsage}`)}`;
				return new Text(text, 0, 0);
			}

			// Fallback
			const header = theme.fg("accent", `${details.mode}: ${details.results.length}`);
			const lines = details.results.map((r) => {
				const icon = r.exitCode !== 0 ? theme.fg("error", "✗") : theme.fg("success", "✓");
				return `${icon} ${theme.fg("accent", r.agent)}`;
			});
			return new Text([header, ...lines].join("\n\n"), 0, 0);
		},
	});
}

// =============================================================================
// Event handler for real-time tracking
// =============================================================================

function handleAgentEvent(
	event: AgentSessionEvent,
	result: SingleResult,
	emitUpdate: () => void,
): void {
	switch (event.type) {
		case "agent_start":
			result.currentActivity = "Starting...";
			emitUpdate();
			break;

		case "turn_start":
			result.currentActivity = "Thinking...";
			emitUpdate();
			break;

		case "message_start":
			if (event.message?.role === "assistant") {
				result.currentActivity = "Generating response...";
				emitUpdate();
			}
			break;

		case "message_update":
			switch (event.assistantMessageEvent?.type) {
				case "thinking_start":
					result.currentActivity = "Thinking...";
					emitUpdate();
					break;
				case "thinking_delta": {
					const delta = event.assistantMessageEvent.delta || "";
					result.partialThinking = appendLiveText(result.partialThinking, delta);
					result.currentActivity = "Thinking...";
					const lines = toPreviewLines(result.partialThinking, 2);
					if (lines.length > 0) setActivityBlock(result, "thinking", lines);
					emitUpdate();
					break;
				}
				case "thinking_end":
					result.currentActivity = "Planning next action...";
					emitUpdate();
					break;
				case "toolcall_start":
					result.currentActivity = "Preparing tools...";
					emitUpdate();
					break;
				case "toolcall_end":
					result.lastToolCall = {
						name: event.assistantMessageEvent.toolCall.name,
						args: event.assistantMessageEvent.toolCall.arguments,
					};
					if (!result.recentToolCalls) result.recentToolCalls = [];
					result.recentToolCalls.push(result.lastToolCall);
					if (result.recentToolCalls.length > LIVE_TOOL_WINDOW_SIZE) {
						result.recentToolCalls.splice(0, result.recentToolCalls.length - LIVE_TOOL_WINDOW_SIZE);
					}
					result.currentActivity = `Queued ${event.assistantMessageEvent.toolCall.name}...`;
					upsertActivityLine(
						result,
						"tool",
						`→ ${formatToolCallPlain(
							event.assistantMessageEvent.toolCall.name,
							event.assistantMessageEvent.toolCall.arguments,
						)}`,
					);
					emitUpdate();
					break;
				case "text_delta": {
					const delta = event.assistantMessageEvent.delta || "";
					result.partialOutput = appendLiveText(result.partialOutput, delta);
					result.currentActivity = "Generating response...";
					clearActivityBlock(result, "thinking");
					const lines = toPreviewLines(result.partialOutput, 4);
					if (lines.length > 0) setActivityBlock(result, "output", lines);
					emitUpdate();
					break;
				}
			}
			break;

		case "message_end":
			if (event.message) {
				if (event.message.role === "assistant") {
					const msg = event.message;
					result.usage.turns++;
					const usage = msg.usage;
					if (usage) {
						result.usage.input += usage.input || 0;
						result.usage.output += usage.output || 0;
						result.usage.cacheRead += usage.cacheRead || 0;
						result.usage.cacheWrite += usage.cacheWrite || 0;
						result.usage.cost += usage.cost?.total || 0;
						result.usage.contextTokens = usage.totalTokens || 0;
					}
					if (!result.model && msg.model) result.model = msg.model;
					if (msg.stopReason) result.stopReason = msg.stopReason;
					if (msg.errorMessage) result.errorMessage = msg.errorMessage;
					result.currentActivity = msg.stopReason === "toolUse" ? "Using tools..." : "Complete";
				}
				emitUpdate();
			}
			break;

		case "tool_execution_start":
			result.currentActivity = `Running ${event.toolName}...`;
			result.lastToolCall = { name: event.toolName, args: event.args };
			if (!result.recentToolCalls) result.recentToolCalls = [];
			result.recentToolCalls.push({ name: event.toolName, args: event.args });
			if (result.recentToolCalls.length > LIVE_TOOL_WINDOW_SIZE) {
				result.recentToolCalls.splice(0, result.recentToolCalls.length - LIVE_TOOL_WINDOW_SIZE);
			}
			upsertActivityLine(result, "tool", `→ ${formatToolCallPlain(event.toolName, event.args)}`);
			emitUpdate();
			break;

		case "tool_execution_end":
			result.currentActivity = "Processing result...";
			emitUpdate();
			break;

		case "turn_end":
			result.currentActivity = "Turn complete";
			emitUpdate();
			break;

		case "agent_end":
			result.currentActivity = "Finished";
			emitUpdate();
			break;
	}
}
