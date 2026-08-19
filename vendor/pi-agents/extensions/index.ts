/**
 * Entry point of the Agents extension.
 *
 * Registers all components:
 *   - `delegate` tool (delegation to sub-agents)
 *   - architect and skill tools (capability inspection, validation, safe saving)
 *   - read-only session review tools (discovery, statistics, extraction)
 *   - `/agent` command (activation/deactivation)
 *   - `before_agent_start` hook (system prompt injection)
 *
 * Implementations live in the neighbouring modules.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { registerDelegateTool } from "./delegate.js";
import { registerArchitectTools } from "./architect-tools.js";
import { registerSkillTools } from "./skill-tools.js";
import { registerSessionTools } from "./session-tools.js";
import { registerAgentCommand, showAgentSelector } from "./cmd-agent.js";
import { registerHooks } from "./hook.js";
import type { ActiveAgentState } from "./types.js";

export default function (pi: ExtensionAPI) {
  // State shared between the command and the hook
  let activeAgentState: ActiveAgentState | null = null;

  const getState = () => activeAgentState;
  const setState = (s: ActiveAgentState | null) => {
    activeAgentState = s;
  };

  // Registration
  registerDelegateTool(pi, () => activeAgentState?.name ?? null);
  registerArchitectTools(pi);
  registerSkillTools(pi);
  registerSessionTools(pi);
  registerAgentCommand(pi, getState, setState);
  registerHooks(pi, () => activeAgentState?.name ?? null, {
    // The global/workspace default and PI_DEFAULT_AGENT are resolved at
    // session start, when the current workspace cwd is available.
    setActiveAgentState: setState,
  });

  // Shortcut Alt+A → agent selector
  pi.registerShortcut("alt+a", {
    description: "Select an agent",
    handler: async (ctx) => {
      await showAgentSelector(pi, ctx, getState, setState);
    },
  });

  // Clear the env var on shutdown to avoid false positives
  pi.on("session_shutdown", async () => {
    delete process.env.PI_ACTIVE_AGENT;
  });
}
