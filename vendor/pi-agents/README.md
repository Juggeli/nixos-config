# @nerisma/pi-agents

<div align="center"><pre>
██████╗ ██╗       █████╗  ██████╗ ███████╗███╗   ██╗████████╗███████╗
██╔══██╗██║      ██╔══██╗██╔════╝ ██╔════╝████╗  ██║╚══██╔══╝██╔════╝
██████╔╝██║█████╗███████║██║  ███╗█████╗  ██╔██╗ ██║   ██║   ███████╗
██╔═══╝ ██║╚════╝██╔══██║██║   ██║██╔══╝  ██║╚██╗██║   ██║   ╚════██║
██║     ██║      ██║  ██║╚██████╔╝███████╗██║ ╚████║   ██║   ███████║
╚═╝     ╚═╝      ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝
                                                                     
</pre></div>

<div align="center">

> A specialized-agent system for [pi](https://www.npmjs.com/package/@earendil-works/pi-coding-agent).

</div>

`pi-agents` lets you switch from a general coding assistant to a focused role with a dedicated prompt, a least-privilege tool set, optional skills, and an appropriate model. It also provides safe workflows for creating agents and Pi extensions, authoring Agent Skills, and reviewing persisted sessions with evidence-based recommendations.

## What you get

| System agent | Use it when you want to… |
|---|---|
| `agent-architect` | Decide whether a need calls for a prompt, skill, tool, or agent, then create an agent when justified — no web access required. |
| `agent-architect-web` | Same role, with web research when external or unstable information matters; requires `pi-web-access`. |
| `agent-skill-creator` | Compare existing public skills, create or adapt a standards-compliant skill, and install it safely. |
| `agent-pi-engineer` | Create or modify a Pi extension that exposes tools or commands, with the smallest reliable change. |
| `agent-session-reviewer` | Audit a session, including decision quality, tool usage, missed parallelism, and opportunities for agents, skills, or tools. |
| `planner` | Explore a change in read-only mode and produce an implementation plan; delegates targeted code harvesting when entry points are unknown. |
| `code-explorer` | Harvest relevant files, symbols, line ranges, and snippets through a read-only funnel for an agent that will reason from them. |
| `builder` | Execute an established implementation plan, validate it, and create a focused local commit. |

The extension supports two execution modes:

- **Agent mode** replaces the current system prompt and enforces the selected agent's tool allow-list before the request reaches the model.
- **Delegation** runs a specialized agent in an isolated in-process session, returning its result with usage and cost metrics.

## Philosophy

`pi-agents` is built on four principles drawn from how the agents themselves operate:

- **Least invention.** Before creating an agent, skill, or tool, first check whether an existing capability, a one-off prompt, or a native pi feature already covers the need. The architect agents enforce this explicitly.
- **Least privilege.** Each agent declares only the tools it actually needs. While an agent is active, the allow-list is reapplied before every provider request, including tools injected by other extensions.
- **Bounded delegation.** A delegated task runs in an isolated session with its own prompt, tools, and model. The main agent keeps its role and context; the sub-agent returns a targeted result with usage metrics.
- **Evidence over opinion.** Session reviews use persisted traces, branch relationships, and tool-level metrics. Recommendations cite concrete occurrences, not general trends.

## Install

Requires **Pi ≥ 0.80.8**.

```bash
pi install npm:@nerisma/pi-agents
```

The eight system agents remain in the installed `pi-agents` package and are read when agents are discovered. They are not copied into `~/.pi/agent/agents/`. Project agents override global agents with the same name, and global agents override system agents.

Reload pi after installation so its extensions and system agents are discovered:

```text
/reload
```

> Upgrading from an earlier release? Remove the previously exported agent files from `~/.pi/agent/agents/` if you want to use the system versions. Keep any file you intentionally customized: global definitions override system agents. The legacy `tool-creator.md` alias can also be removed when no longer needed.

## Quick start

Open the agent selector with `/agent` or `Alt+A`:

```text
/agent
```

The selector groups available agents as project-local, global, then system agents. Empty sections are omitted.

Or activate a role directly:

```text
/agent agent-architect
/agent agent-architect-web
/agent agent-skill-creator
/agent agent-pi-engineer
/agent agent-session-reviewer
/agent planner
/agent code-explorer
/agent builder
```

Return to the normal pi prompt with:

```text
/agent off
```

### Create an agent

```text
/agent agent-architect
Create a project-local agent that reviews database migrations without modifying files.
```

The architect first checks existing capabilities and challenges whether a new agent is needed. If it is, it proposes the prompt, permissions, scope, and final path before writing it. It then validates the saved file and corrects it only if validation fails.

### Choose an architect

`agent-architect` is the offline default. It works with pi alone, including when `pi-fff` replaces pi's native `find` and `grep` tools.

Use `agent-architect-web` only when research on external or unstable information is needed. Install its required extension, then reload pi:

```bash
pi install npm:pi-web-access
```

```text
/reload
```

If `pi-web-access` is absent, activating `agent-architect-web` is refused with this installation command and a reminder to use `/agent agent-architect` instead.

### Create or reuse a skill

```text
/agent agent-skill-creator
I want a project skill for preparing safe PostgreSQL migration plans.
```

The skill creator:

1. clarifies triggers, inputs, outputs, scope, and success criteria;
2. checks loaded skills and searches public sources for close matches;
3. compares reuse, adaptation, and creation, including maintenance, license, dependencies, security, and portability;
4. proposes the exact `SKILL.md`, references, scripts, and assets that are actually needed;
5. writes to a non-discovered draft directory;
6. validates scripts and resources;
7. displays the complete change and asks before installing it.

Project skills are installed under `.pi/skills/<name>/`; global skills go under `~/.pi/agent/skills/<name>/`. Downloading or cloning a public skill and installing dependencies require separate confirmation. External skills and their scripts are treated as untrusted code and reviewed before installation.

### Create or modify a Pi extension

```text
/agent agent-pi-engineer
Add a tool that extracts the schema version from this project's migration files to the nearest project extension.
```

The engineer first asks whether you want a new extension project or to modify an existing one, then produces the smallest reliable change using existing code, Node APIs, and pi APIs.

### Review a session

```text
/agent agent-session-reviewer
Review the latest session for agent-pi-engineer.
```

The reviewer follows persisted branch relationships instead of treating JSONL as a flat log. It evaluates results, permissions, decision quality, validation, repeated Bash work, context usage, and calls that could safely have run in parallel. Recommendations require session evidence; a single occurrence is not presented as a general trend.

## Safety model

Agent definitions declare their tools explicitly. While an agent is active, pi-agents reapplies that allow-list to the request sent to the provider, including tools injected by other extensions.

Agent creation writes the approved definition directly to its final path, then validates it and corrects only validation errors. Skill creation keeps its staged-save workflow because it manages a directory and preserves existing resources omitted from its draft.

## Everyday commands

| Command | Purpose |
|---|---|
| `/agent` | Open the agent selector (`Alt+A` also works). |
| `/agent <name>` | Activate an agent. |
| `/agent off` | Restore the original prompt, tools, model, and thinking level. |
| `/agent-list` | List discovered agents. |
| `/agent-prompt [first]` | Inspect the effective prompt sent for the active agent. |
| `/agent-tools` | Inspect the effective tool list sent to the provider. |
| `/agent-default <name>` | Configure the global agent auto-activated at the next pi start. |
| `/agent-default off` | Clear the global default agent. |
| `/agent-default --workspace <name>` | Configure the current workspace's default agent. |
| `/agent-default --workspace off` | Disable the workspace default and mask the global one. |
| `/agent-default --workspace clear` | Remove the workspace override and inherit the global default. |

Workspace defaults are stored in `<workspace>/.pi/pi-agents.json`. `PI_DEFAULT_AGENT` overrides both workspace and global defaults when set.

## Delegation

The `delegate` tool runs a focused task in an isolated in-process session:

```text
delegate agent=<name> task=<task with all required context>
```

The sub-agent runs in an isolated SDK session with its own composed prompt, tools, model, and thinking level. Output is streamed back with token, cost, duration, and tool-call metrics. Delegation is useful when the main agent should keep its role or context while a specialist handles a bounded subtask. The bundled `planner` delegates only to `code-explorer`, which returns targeted code excerpts rather than an implementation analysis.

## Built-in tools

Specialized tools are registered globally but kept inactive unless an agent explicitly allows them.

### Capability and agent creation

- `agent_capabilities` lists loaded tools, authenticated models, skills, and agents. Use it instead of inventing capability names.
- `agent_validate scope=<global|project|bundled> name=<name>` validates an agent written to its final path.

Agent locations:

- project: `<cwd>/.pi/agents/<name>.md`
- global: `~/.pi/agent/agents/<name>.md`
- bundled: `<cwd>/agents/<NAME_EN_MAJUSCULES>.md`

### Skill creation

- `skill_validate scope=<global|project> name=<name>` checks a complete staged skill directory, its Agent Skills frontmatter, resources, collisions, symlinks, and proposed changes.
- `skill_save scope=<global|project> name=<name>` validates, confirms, overlays, atomically swaps, and verifies the skill directory. Existing files omitted from the draft are preserved.

Skill draft locations:

- project: `<cwd>/.pi/skills/.drafts/<name>/`
- global: `~/.pi/agent/skills/.drafts/<name>/`

Both tools enforce portable Agent Skills names and require a root `SKILL.md` with a non-empty `description`. Detailed knowledge belongs in `references/`, deterministic helpers in `scripts/`, and output resources in `assets/` only when the workflow uses them.

### Session review

- `session_find agentName=<name>` finds recent persisted sessions containing the requested agent on the active branch.
- `session_stats path=<file> agentName=<name>` computes branch-aware tool, cost, model, failure, confirmation, and compaction landmarks.
- `session_extract path=<file> agentName=<name>` returns bounded, redacted evidence with filters, projections, pagination, and causal context.

A typical audit uses `session_stats` first, then targeted `session_extract` calls. Thinking text and obvious credentials are omitted.

## Define your own agents

Agents are discovered from:

- `.pi/agents/*.md` for the current project;
- `~/.pi/agent/agents/*.md` globally;
- the `agents/` directory shipped with `pi-agents` for system agents.

Project agents override global agents with the same name, and global agents override system agents. Each file contains YAML frontmatter followed by its system prompt. Only `name` and `description` are required — every other field is opt-in, so you declare exactly what the agent needs and nothing more:

```markdown
---
name: explorer
description: Explores a codebase and reports where relevant behavior lives
tools: read, fffind, ffgrep
skills: code-review
model: __PI_DEFAULT_MODEL__
thinkingLevel: medium
useAgentFile: true
delegate: agent-architect, agent-session-reviewer
---

Locate the relevant flow and return concise file and symbol references. Do not modify files.
```

| Field | Required | Purpose |
|---|---|---|
| `name` | yes | Unique name used by `/agent` and `delegate`. |
| `description` | yes | Routing guidance shown to models and users. |
| `tools` | no | Explicit allow-list. Omission grants defaults including `bash`; explicit lists are safer. |
| `skills` | no | Skill names advertised to this agent. Project skills are always included and de-duplicated. |
| `model` | no | `provider/model` or a bare model ID. Omitted: current model unchanged. |
| `thinkingLevel` | no | Reasoning level supported by the selected model. Omitted: current level unchanged. |
| `useAgentFile` | no | Append the current directory's `AGENTS.md` when `true`. |
| `delegate` | no | Agent names this agent may delegate to. The `delegate` tool is added automatically. |

Every omitted field inherits the current session's setting: `model` and `thinkingLevel` stay as they were, `tools` default to pi's built-in set including `bash`. This keeps definitions minimal — declare only what must differ. The final prompt is composed with selected skills, allowed delegates, optional project context, environment information, and the current date. Use `/agent-prompt` to inspect the effective result.

## Development

```bash
npm test
npm run typecheck
```

## License

MIT
