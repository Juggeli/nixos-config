/**
 * Per-agent tool restriction resolution.
 *
 * Resolves built-in tool names. The SDK constructs built-in tools from names.
 */

import type { AgentToolRestrictions } from "./types.js";

/** Default restrictions for subagent-mode agents — prevents fork-bombing */
export const SUBAGENT_DEFAULTS: AgentToolRestrictions = {
	subagent: false,
};

/** Restrictions for the explore agent — read-only */
export const EXPLORE_RESTRICTIONS: AgentToolRestrictions = {
	...SUBAGENT_DEFAULTS,
	write: false,
	edit: false,
};

/** Restrictions for the librarian agent — read-only, keeps extension tools */
export const LIBRARIAN_RESTRICTIONS: AgentToolRestrictions = {
	...SUBAGENT_DEFAULTS,
	write: false,
	edit: false,
};

/** All available built-in tool names */
export const ALL_TOOL_NAMES = ["read", "bash", "edit", "write", "grep", "find", "ls"] as const;

/**
 * Resolve the list of built-in tool names allowed for this agent.
 *
 * Tools explicitly set to `false` in the restrictions map are removed.
 */
export function resolveBuiltinToolNames(restrictions: AgentToolRestrictions): string[] {
	return ALL_TOOL_NAMES.filter((name) => restrictions[name] !== false);
}

/**
 * Get the list of tool names that would be allowed given restrictions.
 * Useful for testing without needing cwd or bash policy.
 */
export function resolveToolNames(restrictions: AgentToolRestrictions): string[] {
	return ALL_TOOL_NAMES.filter((name) => restrictions[name] !== false);
}
