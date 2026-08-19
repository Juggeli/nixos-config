/**
 * Shared types for the agent system
 */

export interface AgentConfig {
  name: string;
  description: string;
  tools?: string[];
  /** Skill names selected in frontmatter. Project-local skills are always
   * advertised as well; absent → project-local skills only.
   * `false` → disable all skill injection (even project-local). */
  skills?: string[] | false;
  model?: string;
  thinkingLevel?: string;
  systemPrompt: string;
  source: "system" | "user" | "project";
  filePath: string;
  /** If true, loads AGENTS.md from the current directory and appends it to the
   * system prompt. Silent if absent. */
  useAgentFile?: boolean;
  /** Agent names this agent is allowed to delegate to. The `delegate` tool is
   * injected automatically when set; absent or empty → no delegation. */
  delegate?: string[];
}

export interface AgentUsage {
  input: number;
  output: number;
  cacheRead: number;
  cacheWrite: number;
  cost: number;
}

/**
 * Progress snapshot of a delegated agent, emitted on every sub-process event.
 * Replaces a callback that took 8 positional arguments.
 */
export interface AgentProgress {
  actions: string[];
  activeTools: string[];
  transcript: string;
  usage: AgentUsage;
  durationMs: number;
  toolCount: number;
  toolFailCount: number;
  thinkingPhases: number;
  thinkingText: string;
}

export type AgentProgressCallback = (progress: AgentProgress) => void;

export interface AgentResult {
  agent: string;
  task: string;
  exitCode: number;
  output: string;
  stderr: string;
  usage: AgentUsage;
  model?: string;
  errorMessage?: string;
  actions?: string[];
  durationMs?: number;
  toolCount?: number;
  toolFailCount?: number;
  thinkingPhases?: number;
  thinkingText?: string;
  /** Id of the persisted delegated session (present since delegation now persists). */
  sessionId?: string;
  /** Path of the persisted session file. */
  sessionPath?: string;
  /** Path of the written artifact file for this delegation. */
  artifactPath?: string;
}

export interface DelegateParams {
  /** Management action: list delegated sessions, or resume a completed one. */
  action?: "list" | "resume";
  /** Session id (or unique prefix) for action=resume. */
  id?: string;
  /** Follow-up message for action=resume. */
  message?: string;
  agent?: string;
  task?: string;
}

export interface DelegatedSessionSummary {
  sessionId: string;
  sessionPath: string;
  agent: string;
  task: string;
  cwd: string;
  /** ISO mtime of the session file. */
  modifiedAt: string;
}

export interface DelegateDetails {
  agent: string;
  task: string;
  exitCode: number;
  usage: AgentUsage;
  model?: string;
  errorMessage?: string;
  actions?: string[];
  activeTools?: string[];
  durationMs?: number;
  toolCount?: number;
  toolFailCount?: number;
  thinkingPhases?: number;
  thinkingText?: string;
  sessionId?: string;
  sessionPath?: string;
  artifactPath?: string;
}

export interface ActiveAgentState {
  name: string;
  savedTools: string[];
  savedModelId?: string;
  savedThinkingLevel?: string;
}
