/**
 * Persisted extension config for global and workspace agent defaults.
 *
 * The global config lives at ~/.pi/pi-agents.json. A workspace override lives
 * at <cwd>/.pi/pi-agents.json and may contain null to mask the global default.
 */

import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

interface AgentsConfig {
  /** Name of the agent auto-activated once at session start. */
  defaultAgent?: string | null;
}

function globalConfigPath(): string {
  return path.join(os.homedir(), ".pi", "pi-agents.json");
}

function workspaceConfigPath(cwd: string): string {
  return path.join(cwd, ".pi", "pi-agents.json");
}

function readConfigFile(filePath: string): AgentsConfig {
  try {
    const parsed: unknown = JSON.parse(fs.readFileSync(filePath, "utf-8"));
    return parsed && typeof parsed === "object" ? (parsed as AgentsConfig) : {};
  } catch {
    return {};
  }
}

/** Reads the global config file. */
export function readConfig(): AgentsConfig {
  return readConfigFile(globalConfigPath());
}

/** Writes a config file, creating its parent directory if needed. */
function writeConfig(filePath: string, config: AgentsConfig): void {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, JSON.stringify(config, null, 2) + "\n", "utf-8");
}

function configuredDefault(config: AgentsConfig): string | null | undefined {
  if (!Object.prototype.hasOwnProperty.call(config, "defaultAgent")) {
    return undefined;
  }
  if (config.defaultAgent === null) return null;
  return typeof config.defaultAgent === "string" && config.defaultAgent.trim()
    ? config.defaultAgent
    : undefined;
}

/**
 * Returns the workspace override: a name, null for an explicit local disable,
 * or undefined when the workspace inherits the global setting.
 */
export function getWorkspaceDefaultAgentName(
  cwd: string,
): string | null | undefined {
  return configuredDefault(readConfigFile(workspaceConfigPath(cwd)));
}

/**
 * Name of the default agent to auto-activate at startup.
 * PI_DEFAULT_AGENT (env) takes precedence over workspace and global config.
 */
export function getDefaultAgentName(cwd?: string): string | undefined {
  if (process.env.PI_DEFAULT_AGENT) return process.env.PI_DEFAULT_AGENT;

  if (cwd) {
    const workspaceDefault = getWorkspaceDefaultAgentName(cwd);
    if (workspaceDefault !== undefined) return workspaceDefault ?? undefined;
  }

  return configuredDefault(readConfig()) ?? undefined;
}

/** Sets (or clears, when name is undefined) the persisted global default. */
export function setDefaultAgentName(name: string | undefined): void {
  const config = readConfig();
  if (name) config.defaultAgent = name;
  else delete config.defaultAgent;
  writeConfig(globalConfigPath(), config);
}

/**
 * Sets a workspace default. A null name explicitly disables inheritance;
 * undefined removes the workspace override and restores inheritance.
 */
export function setWorkspaceDefaultAgentName(
  cwd: string,
  name: string | null | undefined,
): void {
  const filePath = workspaceConfigPath(cwd);
  const config = readConfigFile(filePath);
  if (name === undefined) delete config.defaultAgent;
  else config.defaultAgent = name;
  writeConfig(filePath, config);
}
