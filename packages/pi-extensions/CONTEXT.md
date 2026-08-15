# Pi Extensions

Homegrown and vendored extensions for the pi coding agent, managed as one npm
workspace. Each package under `packages/` ships a pi extension entry point and
its supporting modules.

## Language

**Agent**:
A named subagent definition (a markdown file with frontmatter) describing how a
child pi session behaves — its tools, prompt, and optional model. subagents-lite
exposes `explore`, `review`, `researcher`, and `general-purpose`.
_Avoid_: bot, role, worker

**Run**:
One spawned child pi session executing a task for an Agent. Runs have stable
resume handles.
_Avoid_: job, spawn, session (ambiguous with the parent session)

**Override**:
A human-picked model for one Agent, stored in
`subagents.agentOverrides.<agent>.model` of `~/.pi/agent/settings.json`,
optionally with a thinking level suffix (`provider/id:level`). Wins over the
agent's own frontmatter model for builtin agents.
_Avoid_: setting, config

**Inherit**:
What an Agent does with no Override and no frontmatter model: it runs on the
parent session's currently selected model.
_Avoid_: default (ambiguous with pi's own `defaultModel`)

**Picker**:
The `/subagents` TUI command in subagents-lite: the only surface for choosing
Agent models and thinking levels. Picks are committed to settings.json
immediately.
_Avoid_: selector (the upstream chain-clarify widget)

**Profile**:
An upstream pi-subagents bundle of per-Agent model Overrides (quota or quality
tier) generated from a provider catalog and applied wholesale to settings.json.
Distinct from per-Agent picking.
_Avoid_: preset (a pi core concept for the parent session)

**Model scope**:
The upstream `subagents.modelScope` enforcement fence for unattended model
choice. Deliberately not wired into the Picker — model choice here is a human
act (see ADR 0001).

**Wrapper**:
The extension entry point a package owns (`extensions/index.ts`) and any
modules it adds. Wrapper code may import vendored code, never the other way.
_Avoid_: shim, adapter

**Vendored**:
The copy of upstream pi-subagents under a package's `src/`, kept aligned with
upstream so re-vendoring stays possible. Local invention does not go here.
_Avoid_: fork
