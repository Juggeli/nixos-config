/**
 * Per-agent tool restriction resolution.
 *
 * Resolves built-in tool names plus an optional custom bash tool for non-default
 * bash policies. The SDK constructs built-in tools from names; custom tools are
 * passed via `customTools`.
 */

import type { ToolDefinition } from "@mariozechner/pi-coding-agent";
import { createReadOnlyBashTool, createResearchBashTool } from "./read-only-bash.js";
import type { AgentToolRestrictions, BashPolicy } from "./types.js";

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
 * Tools explicitly set to `false` in the restrictions map are removed. When a
 * non-default bash policy is in effect, "bash" is excluded so the custom bash
 * tool from {@link resolveCustomBashTool} can take its place via `customTools`.
 */
export function resolveBuiltinToolNames(
	restrictions: AgentToolRestrictions,
	bashPolicy: BashPolicy = "default",
): string[] {
	return ALL_TOOL_NAMES.filter((name) => {
		if (restrictions[name] === false) return false;
		if (name === "bash" && bashPolicy !== "default") return false;
		return true;
	});
}

/**
 * Resolve the custom bash tool for non-default bash policies.
 *
 * Returns undefined when bashPolicy is "default" (the SDK's built-in bash is
 * used) or when bash is denied by restrictions.
 */
export function resolveCustomBashTool(
	cwd: string,
	restrictions: AgentToolRestrictions,
	bashPolicy: BashPolicy = "default",
): ToolDefinition | undefined {
	if (restrictions.bash === false) return undefined;
	if (bashPolicy === "read-only") return createReadOnlyBashTool(cwd) as unknown as ToolDefinition;
	if (bashPolicy === "research") return createResearchBashTool(cwd) as unknown as ToolDefinition;
	return undefined;
}

/**
 * Get the list of tool names that would be allowed given restrictions.
 * Useful for testing without needing cwd or bash policy.
 */
export function resolveToolNames(restrictions: AgentToolRestrictions): string[] {
	return ALL_TOOL_NAMES.filter((name) => restrictions[name] !== false);
}
