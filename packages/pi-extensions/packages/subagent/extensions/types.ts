/**
 * Shared types for the subagent extension.
 */

import type { ThinkingLevel } from "@mariozechner/pi-agent-core";
import type { Message } from "@mariozechner/pi-ai";
import type { AgentSessionEvent } from "@mariozechner/pi-coding-agent";

// =============================================================================
// Agent Configuration
// =============================================================================

/** Agent execution mode — controls where the agent can be used */
export type AgentMode = "primary" | "subagent" | "all";

/** Bash execution policy for an agent */
export type BashPolicy = "default" | "read-only" | "research";

/**
 * Per-agent tool restrictions.
 * true = allowed, false = denied. Unlisted tools use default (allowed).
 */
export interface AgentToolRestrictions {
	[toolName: string]: boolean;
}

/** Configuration for a single agent */
export interface AgentConfig {
	name: string;
	description: string;
	mode: AgentMode;
	model?: string;
	thinkingLevel?: ThinkingLevel;
	systemPrompt: string;
	tools: AgentToolRestrictions;
	category?: string;
	/** When true, load extensions in the child session (gives access to exa_search, grep_code_search, etc.) */
	loadExtensions?: boolean;
	/** Optional bash safety profile. Use "read-only" or "research" for allowlisted commands only. */
	bashPolicy?: BashPolicy;
	/** When true, live rendering collapses to a compact tool-focused preview. */
	compactLivePreview?: boolean;
}

/** Factory function that produces an AgentConfig */
export type AgentFactory = () => AgentConfig;

// =============================================================================
// Usage & Results
// =============================================================================

export interface UsageStats {
	input: number;
	output: number;
	cacheRead: number;
	cacheWrite: number;
	cost: number;
	contextTokens: number;
	turns: number;
}

export interface TaskResult {
	exitCode: number;
	messages: Message[];
	usage: UsageStats;
	finalOutput: string;
	errorMessage?: string;
}

// =============================================================================
// Tool Details (for renderCall / renderResult)
// =============================================================================

export interface SingleResult {
	agent: string;
	task: string;
	exitCode: number;
	messages: Message[];
	usage: UsageStats;
	sessionId?: string;
	model?: string;
	stopReason?: string;
	errorMessage?: string;
	compactLivePreview?: boolean;
	// Real-time activity tracking
	currentActivity?: string;
	partialThinking?: string;
	partialOutput?: string;
	recentActivityLines?: { key: string; text: string }[];
	lastToolCall?: { name: string; args: Record<string, unknown> };
	recentToolCalls?: { name: string; args: Record<string, unknown> }[];
}

export interface SubagentDetails {
	mode: "single" | "parallel";
	results: SingleResult[];
}

export type DisplayItem =
	| { type: "text"; text: string }
	| { type: "toolCall"; name: string; args: Record<string, any> };

// =============================================================================
// Callbacks
// =============================================================================

export type OnUpdateCallback = (partial: {
	content: { type: "text"; text: string }[];
	details: SubagentDetails;
}) => void;

export type OnAgentEventCallback = (event: AgentSessionEvent) => void;

// =============================================================================
// Constants
// =============================================================================

export const MAX_PARALLEL_TASKS = 8;
export const MAX_CONCURRENCY = 4;
export const COLLAPSED_ITEM_COUNT = 10;
export const ACTIVITY_WINDOW_SIZE = 5;
export const LIVE_TEXT_WINDOW_SIZE = 1200;
export const LIVE_TOOL_WINDOW_SIZE = 5;

export function emptyUsage(): UsageStats {
	return { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, contextTokens: 0, turns: 0 };
}
