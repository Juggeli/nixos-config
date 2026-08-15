# Human-only model selection for subagents

Upstream pi-subagents lets the orchestrating LLM pass `model` parameters in
every tool call and chain step, and provides model-scope enforcement to fence
that unattended choice in. We chose the opposite: the `subagent` tool schema
exposes no `model` parameter, bundled agent frontmatter carries no model or
thinking pins, and the `/subagents` picker is the only selection surface,
writing human picks to `subagents.agentOverrides` in settings.json. Cost and
model governance stays a deliberate human decision; agents inherit the parent
session's model unless a human says otherwise.

## Considered options

- Expose `model` in the tool schema like upstream and lean on `modelScope`
  enforcement for guardrails — rejected: enforcement polices automation that
  should not exist here, and LLM-chosen models reopen the cost-control hole.
- Per-run picker interception at spawn time — rejected: runs are launched by
  the LLM; a human picker cannot interpose cleanly mid-turn.

## Consequences

- Re-vendoring upstream must not reintroduce `model` parameters into the
  wrapper's tool schema.
- An agent that later gains a `model:` frontmatter pin (custom agents) will
  silently beat settings overrides; the picker's `[agent]` source marker is
  the tell.
- `subagents.modelScope` remains dormant and is intentionally ignored by the
  picker.
