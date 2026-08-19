# Fork of @nerisma/pi-agents

Vendored from https://github.com/sebastienservouze/pi-agents at commit
`eeaa7af0eb877d01fd7b72a65ba85dac7a0d261c` (v1.4.0).

Local changes on top of upstream:
- Bundled French-language system agents (planner, builder, code-explorer,
  agent-architect*, agent-skill-creator, agent-pi-engineer,
  agent-session-reviewer) removed; only project/global agents are discovered.
- Delegated agent sessions persist as files under
  `<agentDir>/delegated-sessions/` instead of in-memory sessions.
- `delegate` tool gains `action=list` and `action=resume` (`id` + `message`)
  to list and continue completed delegations with full prior context.
- Delegation results are written to
  `<agentDir>/delegated-sessions/artifacts/<sessionId>.md`.
- `useAgentFile: true` agents now get the project context files
  (AGENTS.md etc.) in delegation mode via `loadProjectContextFiles`.
- Delegation timeout configurable via `PI_AGENTS_TIMEOUT_MS`
  (default 600000 = 10 min).
Rebase procedure: clone upstream, diff against `extensions/`, re-apply the
changes above (`extensions/runner.ts`, `extensions/delegate.ts`,
`extensions/types.ts`), then run `npm ci && npx tsc --noEmit && npm test`
in this directory.
