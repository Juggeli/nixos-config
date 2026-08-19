/**
 * Runs an agent in an isolated in-process SDK session.
 *
 * Each agent runs in its own `createAgentSession`, persisted as a session
 * file under `<agentDir>/delegated-sessions/`, with its own model, tools and
 * system prompt. `pi-agents` itself is
 * excluded from the sub-session's extensions (no `/agent`, no auto-activation,
 * no recursive `delegate`) via `extensionsOverride` on the resource loader —
 * every other extension (context-mode, etc.) is loaded normally so the
 * delegated agent keeps access to their tools when its frontmatter allows
 * them. The `tools:` allow-list itself is enforced natively by the SDK
 * (`CreateAgentSessionOptions.tools`), including for tools registered late by
 * other extensions (e.g. context-mode's lazily-bootstrapped MCP bridge) — no
 * custom guard hook is needed.
 *
 * The system prompt is injected natively via `systemPromptOverride` on the
 * resource loader (replaces pi's default prompt without depending on this
 * extension being loaded in the sub-session), composed with a delegation
 * notice, the project context files (AGENTS.md, when `useAgentFile: true`),
 * an environment block and the current date.
 *
 * The session emits AgentSessionEvent objects (message_update,
 * tool_execution_start/end, message_end…) consumed in real time via
 * `session.subscribe()` to:
 *   - Track activity (tools used, thinking, writing)
 *   - Accumulate consumption metrics (tokens, cost)
 *   - Collect the final output
 */

import * as fs from "node:fs";
import * as path from "node:path";
import {
  createAgentSession,
  DefaultResourceLoader,
  loadProjectContextFiles,
  ModelRuntime,
  parseSessionEntries,
  SessionManager,
  type AgentSession,
  type AgentSessionEvent,
} from "@earendil-works/pi-coding-agent";
import type { ThinkingLevel } from "@earendil-works/pi-agent-core";
import { getAgentDir } from "./registry.js";
import {
  contextFilesSnippet,
  currentDateSnippet,
  delegationSnippet,
  environmentSnippet,
} from "./prompt-build.js";
import type {
  AgentConfig,
  AgentResult,
  AgentUsage,
  AgentProgress,
  AgentProgressCallback,
  DelegatedSessionSummary,
} from "./types.js";

// ─── Formatting helpers ───────────────────────────────────────────────────────

export function formatTokens(n: number): string {
  if (n < 1000) return String(n);
  return `${(n / 1000).toFixed(1)}k`;
}

export function formatDuration(ms: number): string {
  if (ms < 1000) return `${ms}ms`;
  const s = ms / 1000;
  if (s < 60) return `${s.toFixed(0)}s`;
  const min = Math.floor(s / 60);
  const sec = Math.floor(s % 60);
  return `${min}m${sec.toString().padStart(2, "0")}s`;
}

// ─── Event stream processing ───────────────────────────────────────────────────

type StreamEntry =
  | { type: "text"; text: string }
  | {
      type: "tool";
      id: string;
      name: string;
      detail: string;
      done: boolean;
      failed: boolean;
      result?: string;
    };

interface StreamState {
  entries: StreamEntry[];
  textAcc: string;
  usage: AgentUsage;
  output: string;
  model?: string;
  errorMessage?: string;
  thinkingText: string;
  hasSeenNonThinking: boolean;
  toolCount: number;
  toolFailCount: number;
  thinkingPhases: number;
}

/** Builds the progress snapshot passed to `onUpdate`. */
function snapshot(state: StreamState, durationMs: number): AgentProgress {
  const actions: string[] = [];
  const activeTools: string[] = [];
  const transcriptLines: string[] = [];
  let lastWasTool = false;
  for (const e of state.entries) {
    if (e.type === "text") {
      const truncated =
        e.text.length > 100 ? `${e.text.slice(0, 100)}...` : e.text;
      actions.push(truncated);
      if (lastWasTool && transcriptLines.length > 0) transcriptLines.push("");
      transcriptLines.push(e.text);
      lastWasTool = false;
    } else {
      const label = e.done
        ? `  [${e.failed ? "XX" : "OK"}] ${e.name}${e.detail ? " | " + e.detail : ""}`
        : `  [..] TOOL ${e.name}${e.detail ? " | " + e.detail : ""}`;
      actions.push(label);
      if (!e.done) activeTools.push(label);
      const marker = e.done ? (e.failed ? "✗" : "✓") : "…";
      const verb = e.done ? "" : " TOOL";
      transcriptLines.push(
        `  [${marker}]${verb} ${e.name}${e.detail ? " | " + e.detail : ""}`,
      );
      lastWasTool = true;
    }
  }
  if (state.textAcc) {
    if (lastWasTool && transcriptLines.length > 0) transcriptLines.push("");
    transcriptLines.push(state.textAcc);
  }
  return {
    actions,
    activeTools,
    transcript: transcriptLines.join("\n"),
    usage: { ...state.usage },
    durationMs,
    toolCount: state.toolCount,
    toolFailCount: state.toolFailCount,
    thinkingPhases: state.thinkingPhases,
    thinkingText: state.thinkingText,
  };
}

/**
 * Summarizes a tool call's arguments into a short, readable one-liner
 * (bash command, file path, grep/web-search query, URL…).
 */
function describeToolArgs(args: unknown): string {
  if (typeof args !== "object" || args === null) return "";
  const a = args as Record<string, unknown>;

  // bash: show the command
  if (typeof a.command === "string") {
    return a.command.length > 70 ? a.command.slice(0, 70) + "..." : a.command;
  }
  // read, write, edit, find, ls: path truncated on the left
  if (typeof a.path === "string") {
    return a.path.length > 60 ? "..." + a.path.slice(-57) : a.path;
  }
  // grep: query + path if available
  if (typeof a.query === "string") {
    const suffix = typeof a.path === "string" ? ` in ${a.path}` : "";
    return `"${a.query.slice(0, 40)}"${suffix}`;
  }
  // web_search: first query
  if (Array.isArray(a.queries)) {
    const q = (a.queries as string[])[0] ?? "";
    return `"${q.slice(0, 50)}"`;
  }
  // fetch_content: URL
  if (typeof a.url === "string") {
    return a.url.length > 60 ? "..." + a.url.slice(-57) : a.url;
  }
  // fallback: first argument
  const first = Object.entries(a)[0];
  if (!first) return "";
  const [key, value] = first;
  const str = typeof value === "string" ? value : JSON.stringify(value);
  return `${key}=${str.slice(0, 40)}`;
}

/**
 * Processes one AgentSessionEvent from `session.subscribe()`. Same shape and
 * semantics as the former `pi --mode json` stdout events (message_update,
 * tool_execution_start/end, message_end) — this is a direct mapping, not a
 * behavioral change.
 */
function processEvent(
  event: AgentSessionEvent,
  state: StreamState,
  startTime: number,
  onUpdate?: AgentProgressCallback,
): void {
  const elapsed = Date.now() - startTime;

  switch (event.type) {
    // ── Text streaming ──
    case "message_update": {
      const ame = event.assistantMessageEvent as
        { type: string; delta?: string } | undefined;
      if (!ame) return;

      // Thinking-phase counter: incremented even after non-thinking content
      if (ame.type === "thinking_start") {
        state.thinkingPhases++;
      }

      // Ignore thinking_delta only after we've seen non-thinking content.
      if (state.hasSeenNonThinking && ame.type === "thinking_delta") {
        return;
      }

      // Mark that we've seen real content
      if (
        ame.type === "text_delta" ||
        ame.type === "text_start" ||
        ame.type === "toolcall_delta" ||
        ame.type === "toolcall_start"
      ) {
        state.hasSeenNonThinking = true;
      }

      // Accumulate thinking text but skip in transcript
      if (ame.type === "thinking_delta") {
        state.thinkingText += ame.delta ?? "";
      }

      // Accumulate real text deltas for the transcript
      if (ame.type === "text_delta") {
        state.textAcc += ame.delta ?? "";
      }

      onUpdate?.(snapshot(state, elapsed));
      break;
    }

    // ── Tool start ──
    case "tool_execution_start": {
      // Flush any accumulated agent text before the tool
      if (state.textAcc) {
        state.entries.push({ type: "text", text: state.textAcc });
        state.textAcc = "";
      }
      const { toolCallId, toolName, args } = event;
      const detail = describeToolArgs(args);
      state.entries.push({
        type: "tool",
        id: toolCallId,
        name: toolName,
        detail,
        done: false,
        failed: false,
      });
      state.toolCount++;
      onUpdate?.(snapshot(state, elapsed));
      break;
    }

    // ── Tool end ──
    case "tool_execution_end": {
      // Flush any accumulated agent text before resolving the tool
      if (state.textAcc) {
        state.entries.push({ type: "text", text: state.textAcc });
        state.textAcc = "";
      }
      const { toolCallId, isError } = event;
      const entry = state.entries.find(
        (e) => e.type === "tool" && e.id === toolCallId,
      );
      if (entry && entry.type === "tool") {
        entry.done = true;
        entry.failed = isError;
        // Extract result text for the transcript
        const result = event.result as
          { content?: Array<{ type: string; text?: string }> } | undefined;
        if (result?.content) {
          const texts = result.content
            .filter(
              (c): c is { type: "text"; text: string } =>
                c.type === "text" && typeof c.text === "string",
            )
            .map((c) => c.text);
          if (texts.length) entry.result = texts.join("\n");
        }
      }
      if (isError) state.toolFailCount++;
      onUpdate?.(snapshot(state, elapsed));
      break;
    }

    // ── Final message ──
    case "message_end": {
      const msg = event.message as {
        role?: string;
        usage?: {
          input?: number;
          output?: number;
          cacheRead?: number;
          cacheWrite?: number;
          cost?: { total?: number };
        };
        model?: string;
        errorMessage?: string;
        content?: Array<{ type: string; text?: string }>;
      };
      if (!msg || msg.role !== "assistant") return;

      if (msg.usage) {
        state.usage.input += msg.usage.input || 0;
        state.usage.output += msg.usage.output || 0;
        state.usage.cacheRead += msg.usage.cacheRead || 0;
        state.usage.cacheWrite += msg.usage.cacheWrite || 0;
        state.usage.cost += msg.usage.cost?.total || 0;
      }
      if (!state.model && msg.model) state.model = msg.model;
      if (msg.errorMessage) state.errorMessage = msg.errorMessage;

      // Flush accumulated text as a definitive entry, or use message content
      if (state.textAcc) {
        state.entries.push({ type: "text", text: state.textAcc });
        state.textAcc = "";
      } else {
        for (const part of msg.content ?? []) {
          if (part.type === "text" && part.text) {
            state.entries.push({ type: "text", text: part.text });
          }
        }
      }

      // Reset thinking accumulator for the next message
      state.thinkingText = "";
      onUpdate?.(snapshot(state, elapsed));
      break;
    }

    // ── Agent finished ──
    case "agent_end": {
      if (event.willRetry) break;
      const msgs = event.messages as Array<{
        role?: string;
        content?: Array<{ type: string; text?: string }>;
      }>;
      for (let i = msgs.length - 1; i >= 0; i--) {
        const m = msgs[i];
        if (m.role === "assistant" && m.content) {
          const texts = m.content
            .filter(
              (c): c is { type: "text"; text: string } =>
                c.type === "text" && typeof c.text === "string",
            )
            .map((c) => c.text);
          if (texts.length) {
            state.output = texts.join("\n\n");
          }
          break;
        }
      }
      break;
    }
  }
}

// ─── Model resolution ────────────────────────────────────────────────────────

/**
 * Resolves an agent's `model:` frontmatter value ("provider/id" or bare id)
 * against a ModelRuntime. Same lookup rules as activation.ts/hook.ts.
 */
function resolveModel(runtime: ModelRuntime, modelSpec: string | undefined) {
  if (!modelSpec) return undefined;
  const slashIdx = modelSpec.indexOf("/");
  return slashIdx !== -1
    ? runtime.getModel(
        modelSpec.slice(0, slashIdx),
        modelSpec.slice(slashIdx + 1),
      )
    : runtime.getModels().find((m) => m.id === modelSpec);
}

// ─── Execution ────────────────────────────────────────────────────────────────

const AGENT_TIMEOUT_MS =
  Number.parseInt(process.env.PI_AGENTS_TIMEOUT_MS ?? "", 10) || 600_000; // 10 min

// ─── Delegated session persistence ────────────────────────────────────────────

/** Custom entry type marking a session file as a pi-agents delegation. */
export const DELEGATION_META_TYPE = "pi-agents-delegation";

/** Directory where delegated agent sessions are persisted. */
export function delegatedSessionDir(): string {
  return path.join(getAgentDir(), "delegated-sessions");
}

/** Strips the `<timestamp>_` prefix pi puts in session file names. */
function bareSessionId(fileName: string): string {
  return fileName.replace(/\.jsonl$/, "").replace(/^\d{4}-\d{2}-\d{2}T[\d-]+Z_/, "");
}

interface DelegationMeta {
  agent: string;
  task: string;
  cwd: string;
}

function readDelegationMeta(sessionPath: string): DelegationMeta | undefined {
  try {
    const content = fs.readFileSync(sessionPath, "utf-8");
    for (const entry of parseSessionEntries(content)) {
      if (
        entry.type === "custom" &&
        entry.customType === DELEGATION_META_TYPE
      ) {
        const data = entry.data as Partial<DelegationMeta> | undefined;
        if (data?.agent && data.task !== undefined && data.cwd) {
          return { agent: data.agent, task: data.task, cwd: data.cwd };
        }
      }
    }
  } catch {
    /* unreadable session — treated as not found */
  }
  return undefined;
}

/** Lists persisted delegated sessions, newest first. */
export function listDelegatedSessions(): DelegatedSessionSummary[] {
  const dir = delegatedSessionDir();
  let files: fs.Dirent[];
  try {
    files = fs.readdirSync(dir, { withFileTypes: true });
  } catch {
    return [];
  }
  const summaries: DelegatedSessionSummary[] = [];
  for (const f of files) {
    if (!f.isFile() || !f.name.endsWith(".jsonl")) continue;
    const sessionPath = path.join(dir, f.name);
    const meta = readDelegationMeta(sessionPath);
    if (!meta) continue;
    summaries.push({
      sessionId: bareSessionId(f.name),
      sessionPath,
      agent: meta.agent,
      task: meta.task,
      cwd: meta.cwd,
      modifiedAt: fs.statSync(sessionPath).mtime.toISOString(),
    });
  }
  summaries.sort((a, b) => b.modifiedAt.localeCompare(a.modifiedAt));
  return summaries;
}

/**
 * Finds a delegated session by id or unique prefix.
 * Returns the opened SessionManager plus its metadata.
 */
export function findDelegatedSession(
  idOrPrefix: string,
): { manager: SessionManager; meta: DelegationMeta; sessionId: string; sessionPath: string } | undefined {
  const dir = delegatedSessionDir();
  let files: string[];
  try {
    files = fs.readdirSync(dir);
  } catch {
    return undefined;
  }
  const matches = files.filter((f) => {
    if (!f.endsWith(".jsonl")) return false;
    return (
      bareSessionId(f).startsWith(idOrPrefix) ||
      f.slice(0, -6).startsWith(idOrPrefix)
    );
  });
  if (matches.length === 0) return undefined;
  if (matches.length > 1) {
    throw new Error(
      `Ambiguous session prefix "${idOrPrefix}": matches ${matches.length} sessions.`,
    );
  }
  const sessionPath = path.join(dir, matches[0]);
  const meta = readDelegationMeta(sessionPath);
  if (!meta) return undefined;
  const manager = SessionManager.open(sessionPath);
  return {
    manager,
    meta,
    sessionId: bareSessionId(matches[0]),
    sessionPath,
  };
}

/** Writes the delegation result to a markdown artifact, returns its path. */
function writeDelegationArtifact(result: AgentResult): string | undefined {
  if (!result.sessionId) return undefined;
  const dir = path.join(delegatedSessionDir(), "artifacts");
  fs.mkdirSync(dir, { recursive: true });
  const artifactPath = path.join(dir, `${result.sessionId}.md`);
  const lines = [
    `# Delegation: ${result.agent}`,
    "",
    `- session: ${result.sessionId}`,
    `- model: ${result.model ?? "default"}`,
    `- duration: ${result.durationMs ? formatDuration(result.durationMs) : "n/a"}`,
    `- tokens: in ${formatTokens(result.usage.input)}, out ${formatTokens(result.usage.output)}, cost $${(result.usage.cost || 0).toFixed(4)}`,
    "",
    "## Task",
    "",
    result.task,
    "",
    "## Output",
    "",
    result.output || "(no output)",
  ];
  if (result.actions?.length) {
    lines.push("", "## Actions", "", ...result.actions.map((a) => `- ${a}`));
  }
  fs.writeFileSync(artifactPath, `${lines.join("\n")}\n`, "utf-8");
  return artifactPath;
}
/**
 * Runs an agent in an isolated in-process SDK session.
 */
export async function runAgent(
  cwd: string,
  agent: AgentConfig,
  task: string,
  signal?: AbortSignal,
  onUpdate?: AgentProgressCallback,
  resume?: { manager: SessionManager; sessionId: string; sessionPath: string },
): Promise<AgentResult> {
  const startTime = Date.now();
  const agentDir = getAgentDir();

  // Composed prompt: agent .md + delegation notice + project context files
  // (AGENTS.md et al., gated by useAgentFile) + environment + date.
  // (Skills are not resolved here: they live in the parent's loader; the
  // sub-session loads its own if skills support is added later.)
  const finalPrompt =
    agent.systemPrompt +
    delegationSnippet(agent.name) +
    (agent.useAgentFile
      ? contextFilesSnippet(loadProjectContextFiles({ cwd, agentDir }), cwd)
      : "") +
    environmentSnippet(cwd, agent.model) +
    currentDateSnippet();

  const result: AgentResult = {
    agent: agent.name,
    task,
    exitCode: 0,
    output: "",
    stderr: "",
    usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0 },
    model: agent.model,
  };
  if (resume) {
    result.sessionId = resume.sessionId;
    result.sessionPath = resume.sessionPath;
  }

  const state: StreamState = {
    entries: [],
    textAcc: "",
    usage: { ...result.usage },
    output: "",
    thinkingText: "",
    hasSeenNonThinking: false,
    toolCount: 0,
    toolFailCount: 0,
    thinkingPhases: 0,
  };

  let wasAborted = false;
  let session: AgentSession | undefined;
  let unsubscribe: (() => void) | undefined;
  let tickInterval: ReturnType<typeof setInterval> | undefined;
  let timeoutId: ReturnType<typeof setTimeout> | undefined;
  let onAbort: (() => void) | undefined;

  try {
    // ── Session persistence: file-backed so a delegation can be resumed ──
    const sessionManager =
      resume?.manager ?? SessionManager.create(cwd, delegatedSessionDir());
    if (!resume) {
      sessionManager.appendCustomEntry(DELEGATION_META_TYPE, {
        agent: agent.name,
        task,
        cwd,
      });
      sessionManager.appendSessionInfo(
        `${agent.name}: ${task.length > 60 ? `${task.slice(0, 60)}…` : task}`,
      );
    }
    // ── Resource loader: exclude pi-agents, keep every other extension ──
    // (context-mode, etc.) so the delegated agent gets their tools if its
    // frontmatter `tools:` allows them. Excluding pi-agents avoids its
    // /agent + auto-activation + delegate machinery firing recursively
    // inside the sub-session and overwriting the systemPrompt/tools we set
    // here.
    const loader = new DefaultResourceLoader({
      cwd,
      agentDir,
      systemPromptOverride: () => finalPrompt,
      extensionsOverride: (base) => ({
        ...base,
        extensions: base.extensions.filter(
          (ext) => !ext.resolvedPath.includes("/pi-agents/"),
        ),
      }),
    });
    await loader.reload();

    // ponytail: ModelRuntime handles auth and model resolution; AuthStorage
    // and ModelRegistry are removed in pi >= 0.80.8.
    const modelRuntime = await ModelRuntime.create({
      authPath: path.join(agentDir, "auth.json"),
      modelsPath: path.join(agentDir, "models.json"),
    });
    const resolvedModel = resolveModel(modelRuntime, agent.model);

    const { session: createdSession } = await createAgentSession({
      cwd,
      agentDir,
      resourceLoader: loader,
      // Native allow-list enforcement — works even for tools registered late
      // by other extensions (e.g. context-mode's MCP bridge, bootstrapped
      // lazily from its own before_agent_start). No custom guard needed.
      tools: agent.tools?.length ? agent.tools : undefined,
      model: resolvedModel,
      thinkingLevel: agent.thinkingLevel as ThinkingLevel | undefined,
      sessionManager,
      modelRuntime,
    });
    session = createdSession;

    // ── Subscribe: map SDK events to the same StreamState as before ──
    unsubscribe = session.subscribe((event) => {
      processEvent(event, state, startTime, onUpdate);
    });

    // Periodic tick: forces a refresh every second so the displayed duration
    // keeps incrementing even without an event from the sub-agent.
    if (onUpdate) {
      tickInterval = setInterval(() => {
        onUpdate(snapshot(state, Date.now() - startTime));
      }, 1000);
    }

    // ── Timeout / abort plumbing ──
    const abortSession = () => {
      wasAborted = true;
      if (tickInterval) clearInterval(tickInterval);
      if (timeoutId) clearTimeout(timeoutId);
      void session?.abort();
    };

    timeoutId = setTimeout(abortSession, AGENT_TIMEOUT_MS);

    onAbort = abortSession;
    if (signal?.aborted) {
      onAbort();
    } else {
      signal?.addEventListener("abort", onAbort, { once: true });
    }

    // ── Run the prompt (equivalent of `pi --mode json -p --no-session <task>`) ──
    if (!wasAborted) {
      await session.prompt(task);
    }

    if (tickInterval) clearInterval(tickInterval);
    if (timeoutId) clearTimeout(timeoutId);

    // ── Finalization ──
    result.exitCode = wasAborted ? 1 : 0;
    result.output = state.output;
    result.usage = { ...state.usage };
    result.model = state.model || result.model;
    result.errorMessage = state.errorMessage;
    result.actions = state.entries.map((e) => {
      if (e.type === "text") {
        return e.text.length > 100 ? `${e.text.slice(0, 100)}...` : e.text;
      }
      return e.done
        ? `  [${e.failed ? "XX" : "OK"}] ${e.name}${e.detail ? " | " + e.detail : ""}`
        : `  [..] TOOL ${e.name}${e.detail ? " | " + e.detail : ""}`;
    });
    result.durationMs = Date.now() - startTime;
    result.toolCount = state.toolCount;
    result.toolFailCount = state.toolFailCount;
    result.thinkingPhases = state.thinkingPhases;
    result.thinkingText = state.thinkingText;
    if (!result.sessionId) result.sessionId = sessionManager.getSessionId();
    if (!result.sessionPath) result.sessionPath = sessionManager.getSessionFile();
    result.artifactPath = writeDelegationArtifact(result);

    if (wasAborted) {
      throw new Error(
        `Delegation cancelled or timeout reached (${formatDuration(AGENT_TIMEOUT_MS)})`,
      );
    }

    return result;
  } finally {
    if (tickInterval) clearInterval(tickInterval);
    if (timeoutId) clearTimeout(timeoutId);
    if (onAbort) signal?.removeEventListener("abort", onAbort);
    unsubscribe?.();
    session?.dispose();
  }
}
