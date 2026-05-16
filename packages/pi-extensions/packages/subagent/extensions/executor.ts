/**
 * Agent executor — runs agents in-process using the SDK.
 *
 * Replaces the old subprocess-based execution with createAgentSession().
 */

import type { AssistantMessage, Message } from "@earendil-works/pi-ai";
import {
	type AgentSession,
	type AgentSessionEvent,
	type CreateAgentSessionOptions,
	createAgentSession,
	DefaultResourceLoader,
	type ExtensionContext,
	getAgentDir,
	SessionManager,
	SettingsManager,
} from "@earendil-works/pi-coding-agent";
import {
	detectTextLoop,
	detectToolLoop,
	recordTextDelta,
	recordToolCall,
	type TextDeltaWindow,
	type ToolCallWindow,
} from "./loop-detector.js";
import { logSubagentDebug } from "./debug-log.js";
import { getModelOverride } from "./model-config.js";
import { resolveBuiltinToolNames, resolveCustomBashTool } from "./tool-restrictions.js";
import type { AgentConfig, OnAgentEventCallback, SingleResult, TaskResult, UsageStats } from "./types.js";
import { emptyUsage } from "./types.js";

const CHILD_SUBAGENT_BOUNDARY_INSTRUCTIONS = [
	"You are a child subagent, not the parent orchestrator.",
	"Complete only the assigned role-specific task with the tools available to you.",
	"Do not propose or run subagents.",
	"If you need to edit files, call actual edit/write tools. Do not print tool-call syntax, patches, or pseudo-tool calls as text.",
].join("\n");

function buildSubagentPrompt(agentConfig: AgentConfig): string {
	return `${CHILD_SUBAGENT_BOUNDARY_INSTRUCTIONS}\n\n${agentConfig.systemPrompt}`;
}

let piSubagentEnvQueue: Promise<void> = Promise.resolve();

async function withPiSubagentEnv<T>(enabled: boolean | undefined, fn: () => Promise<T>): Promise<T> {
	if (!enabled) return fn();

	const previous = piSubagentEnvQueue.catch(() => undefined);
	let release!: () => void;
	piSubagentEnvQueue = previous.then(() => new Promise<void>((resolve) => {
		release = resolve;
	}));

	await previous;
	const previousPiSubagent = process.env.PI_SUBAGENT;
	process.env.PI_SUBAGENT = "1";
	try {
		return await fn();
	} finally {
		if (previousPiSubagent === undefined) delete process.env.PI_SUBAGENT;
		else process.env.PI_SUBAGENT = previousPiSubagent;
		release();
	}
}

/**
 * Run an agent using the in-process SDK.
 *
 * Creates a child AgentSession with the agent's tool restrictions and system prompt,
 * executes the task, and returns the result. The session is kept alive for potential resume.
 */
export async function runAgent(
	agentConfig: AgentConfig,
	task: string,
	ctx: ExtensionContext,
	signal?: AbortSignal,
	onEvent?: OnAgentEventCallback,
): Promise<{ result: TaskResult; session: AgentSession }> {
	const cwd = ctx.cwd;
	const runId = `${agentConfig.name}-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;

	// Resolve model from registry if specified, with persisted override taking priority.
	// Matching mirrors the main model-resolver: case-insensitive, provider/id then id-only fallback.
	const effectiveModelId = getModelOverride(agentConfig.name) ?? agentConfig.model;
	let model = ctx.model;
	if (effectiveModelId && ctx.modelRegistry) {
		const allModels = ctx.modelRegistry.getAll();
		const lower = effectiveModelId.toLowerCase();
		let found: typeof model | undefined;

		// Try provider/modelId format (case-insensitive)
		const slashIdx = effectiveModelId.indexOf("/");
		if (slashIdx !== -1) {
			const provider = effectiveModelId.substring(0, slashIdx).toLowerCase();
			const modelId = effectiveModelId.substring(slashIdx + 1).toLowerCase();
			found = allModels.find((m) => m.provider.toLowerCase() === provider && m.id.toLowerCase() === modelId);
		}

		// Fall back to exact ID match (case-insensitive)
		if (!found) {
			found = allModels.find((m) => m.id.toLowerCase() === lower);
		}

		// Fall back to full "provider/id" string match (case-insensitive)
		if (!found) {
			found = allModels.find((m) => `${m.provider}/${m.id}`.toLowerCase() === lower);
		}

		if (found) model = found;
	}

	const bashPolicy = agentConfig.bashPolicy ?? "default";
	const systemPromptMode = agentConfig.systemPromptMode ?? "replace";
	const inheritProjectContext = agentConfig.inheritProjectContext ?? false;
	const subagentPrompt = buildSubagentPrompt(agentConfig);
	const builtinToolNames = resolveBuiltinToolNames(agentConfig.tools, bashPolicy);
	const customBash = resolveCustomBashTool(cwd, agentConfig.tools, bashPolicy);
	const toolNames = customBash && !builtinToolNames.includes("bash") ? [...builtinToolNames, "bash"] : builtinToolNames;
	logSubagentDebug("run_start", {
		runId,
		agent: agentConfig.name,
		cwd,
		model: effectiveModelId || "parent",
		bashPolicy,
		systemPromptMode,
		inheritProjectContext,
		toolNames,
		customBash: Boolean(customBash),
		loadExtensions: Boolean(agentConfig.loadExtensions),
		task,
		systemPrompt: subagentPrompt,
	});

	// Create resource loader — load extensions only when the agent requires them
	const resourceLoader = new DefaultResourceLoader({
		cwd,
		agentDir: getAgentDir(),
		noExtensions: !agentConfig.loadExtensions,
		noSkills: true,
		noPromptTemplates: true,
		noThemes: true,
		noContextFiles: !inheritProjectContext,
		systemPrompt: systemPromptMode === "replace" ? subagentPrompt : undefined,
		appendSystemPrompt: systemPromptMode === "append" ? [subagentPrompt] : undefined,
	});
	await withPiSubagentEnv(agentConfig.loadExtensions, () => resourceLoader.reload());

	const sessionOptions: CreateAgentSessionOptions = {
		cwd,
		modelRegistry: ctx.modelRegistry,
		model,
		tools: toolNames,
		customTools: customBash ? [customBash] : undefined,
		resourceLoader,
		sessionManager: SessionManager.inMemory(cwd),
		settingsManager: SettingsManager.create(cwd),
		thinkingLevel: agentConfig.thinkingLevel,
	};

	const { session } = await createAgentSession(sessionOptions);
	logSubagentDebug("session_created", { runId, agent: agentConfig.name });

	// Subscribe to events for real-time updates
	let unsubscribe: (() => void) | undefined;
	if (onEvent) {
		unsubscribe = session.subscribe(onEvent);
	}

	const usage: UsageStats = emptyUsage();
	let loopWindow: ToolCallWindow | undefined;
	let textLoopWindow: TextDeltaWindow | undefined;
	let loopErrorMessage: string | undefined;
	let parentAbortRequested = false;

	const debugUnsub = session.subscribe((event: AgentSessionEvent) => {
		logSubagentDebug("session_event", { runId, agent: agentConfig.name, event });
	});

	// Track usage from events
	const usageUnsub = session.subscribe((event: AgentSessionEvent) => {
		if (event.type === "message_end" && event.message?.role === "assistant") {
			const msg = event.message;
			usage.turns++;
			const msgUsage = msg.usage;
			if (msgUsage) {
				usage.input += msgUsage.input || 0;
				usage.output += msgUsage.output || 0;
				usage.cacheRead += msgUsage.cacheRead || 0;
				usage.cacheWrite += msgUsage.cacheWrite || 0;
				usage.cost += msgUsage.cost?.total || 0;
				usage.contextTokens = msgUsage.totalTokens || 0;
			}
		}
	});
	const loopUnsub = session.subscribe((event: AgentSessionEvent) => {
		if (loopErrorMessage) return;

		if (event.type === "tool_execution_start") {
			loopWindow = recordToolCall(loopWindow, event.toolName, event.args);
			const detection = detectToolLoop(loopWindow);
			if (detection.triggered) {
				loopErrorMessage = detection.reason;
				session.abort();
			}
			return;
		}

		if (event.type === "message_update" && event.assistantMessageEvent?.type === "text_delta") {
			textLoopWindow = recordTextDelta(textLoopWindow, event.assistantMessageEvent.delta || "");
			const detection = detectTextLoop(textLoopWindow);
			if (detection.triggered) {
				loopErrorMessage = detection.reason;
				session.abort();
			}
		}
	});

	try {
		// Handle abort
		if (signal?.aborted) {
			throw new Error("Subagent was aborted");
		}

		let abortHandler: (() => void) | undefined;
		if (signal) {
			abortHandler = () => {
				parentAbortRequested = true;
				session.abort();
			};
			signal.addEventListener("abort", abortHandler, { once: true });
		}

		try {
			// Execute the prompt
			await session.prompt(task, { expandPromptTemplates: false });
		} finally {
			if (signal && abortHandler) {
				signal.removeEventListener("abort", abortHandler);
			}
		}

		// Extract final output from messages
		const messages = session.messages as Message[];
		logSubagentDebug("run_success", { runId, agent: agentConfig.name, messages });
		const finalOutput = extractFinalOutput(messages);
		const lastAssistant = findLastAssistant(messages);

		const result: TaskResult = {
			exitCode: lastAssistant?.errorMessage ? 1 : 0,
			messages,
			usage,
			finalOutput,
			errorMessage: lastAssistant?.errorMessage,
		};

		return { result, session };
	} catch (error) {
		const messages = session.messages as Message[];
		const rawErrorMessage = error instanceof Error ? error.message : String(error);
		logSubagentDebug("run_error", { runId, agent: agentConfig.name, rawErrorMessage, loopErrorMessage, messages });
		const errorMessage =
			loopErrorMessage ??
			(parentAbortRequested || signal?.aborted
				? `Parent aborted subagent: ${rawErrorMessage}`
				: rawErrorMessage === "Request was aborted"
					? "Subagent session was aborted by the SDK/provider without an explicit reason."
					: rawErrorMessage);

		return {
			result: {
				exitCode: 1,
				messages,
				usage,
				finalOutput: "",
				errorMessage,
			},
			session,
		};
	} finally {
		unsubscribe?.();
		debugUnsub();
		usageUnsub();
		loopUnsub();
	}
}

/**
 * Resume an existing agent session with a new task.
 */
export async function resumeAgent(
	session: AgentSession,
	task: string,
	signal?: AbortSignal,
	onEvent?: OnAgentEventCallback,
): Promise<TaskResult> {
	const runId = `resume-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
	logSubagentDebug("resume_start", { runId, task });
	let unsubscribe: (() => void) | undefined;
	if (onEvent) {
		unsubscribe = session.subscribe(onEvent);
	}

	const usage: UsageStats = emptyUsage();
	let loopWindow: ToolCallWindow | undefined;
	let textLoopWindow: TextDeltaWindow | undefined;
	let loopErrorMessage: string | undefined;
	let parentAbortRequested = false;
	const debugUnsub = session.subscribe((event: AgentSessionEvent) => {
		logSubagentDebug("resume_event", { runId, event });
	});
	const usageUnsub = session.subscribe((event: AgentSessionEvent) => {
		if (event.type === "message_end" && event.message?.role === "assistant") {
			const msg = event.message;
			usage.turns++;
			const msgUsage = msg.usage;
			if (msgUsage) {
				usage.input += msgUsage.input || 0;
				usage.output += msgUsage.output || 0;
				usage.cacheRead += msgUsage.cacheRead || 0;
				usage.cacheWrite += msgUsage.cacheWrite || 0;
				usage.cost += msgUsage.cost?.total || 0;
				usage.contextTokens = msgUsage.totalTokens || 0;
			}
		}
	});
	const loopUnsub = session.subscribe((event: AgentSessionEvent) => {
		if (loopErrorMessage) return;

		if (event.type === "tool_execution_start") {
			loopWindow = recordToolCall(loopWindow, event.toolName, event.args);
			const detection = detectToolLoop(loopWindow);
			if (detection.triggered) {
				loopErrorMessage = detection.reason;
				session.abort();
			}
			return;
		}

		if (event.type === "message_update" && event.assistantMessageEvent?.type === "text_delta") {
			textLoopWindow = recordTextDelta(textLoopWindow, event.assistantMessageEvent.delta || "");
			const detection = detectTextLoop(textLoopWindow);
			if (detection.triggered) {
				loopErrorMessage = detection.reason;
				session.abort();
			}
		}
	});

	try {
		if (signal?.aborted) throw new Error("Subagent was aborted");

		let abortHandler: (() => void) | undefined;
		if (signal) {
			abortHandler = () => {
				parentAbortRequested = true;
				session.abort();
			};
			signal.addEventListener("abort", abortHandler, { once: true });
		}

		try {
			await session.prompt(task, { expandPromptTemplates: false });
		} finally {
			if (signal && abortHandler) {
				signal.removeEventListener("abort", abortHandler);
			}
		}

		const messages = session.messages as Message[];
		logSubagentDebug("resume_success", { runId, messages });
		const finalOutput = extractFinalOutput(messages);
		const lastAssistant = findLastAssistant(messages);

		return {
			exitCode: lastAssistant?.errorMessage ? 1 : 0,
			messages,
			usage,
			finalOutput,
			errorMessage: lastAssistant?.errorMessage,
		};
	} catch (error) {
		const messages = session.messages as Message[];
		const rawErrorMessage = error instanceof Error ? error.message : String(error);
		logSubagentDebug("resume_error", { runId, rawErrorMessage, loopErrorMessage, messages });
		return {
			exitCode: 1,
			messages,
			usage,
			finalOutput: "",
			errorMessage:
				loopErrorMessage ??
				(parentAbortRequested || signal?.aborted
					? `Parent aborted subagent: ${rawErrorMessage}`
					: rawErrorMessage === "Request was aborted"
						? "Subagent session was aborted by the SDK/provider without an explicit reason."
						: rawErrorMessage),
		};
	} finally {
		unsubscribe?.();
		debugUnsub();
		usageUnsub();
		loopUnsub();
	}
}

/**
 * Build a SingleResult from a TaskResult for rendering purposes.
 */
export function toSingleResult(
	agentName: string,
	task: string,
	taskResult: TaskResult,
	sessionId?: string,
): SingleResult {
	return {
		agent: agentName,
		task,
		exitCode: taskResult.exitCode,
		messages: taskResult.messages,
		usage: taskResult.usage,
		sessionId,
		errorMessage: taskResult.errorMessage,
	};
}

// =============================================================================
// Helpers
// =============================================================================

function extractFinalOutput(messages: Message[]): string {
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

function findLastAssistant(messages: Message[]): AssistantMessage | undefined {
	for (let i = messages.length - 1; i >= 0; i--) {
		const msg = messages[i];
		if (msg.role === "assistant") return msg;
	}
	return undefined;
}
