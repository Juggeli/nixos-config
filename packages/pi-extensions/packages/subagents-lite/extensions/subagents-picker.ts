import * as fs from "node:fs";
import * as path from "node:path";
import type { ExtensionAPI, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";
import { fuzzyFilter, type SelectItem, SelectList } from "@earendil-works/pi-tui";
import type { ModelInfo } from "../src/shared/model-info.ts";
import { getSupportedThinkingLevels, type ThinkingLevelMap, toModelInfo } from "../src/shared/model-info.ts";
import { getAgentDir } from "../src/shared/utils.ts";

// ---------------------------------------------------------------------------
// Pure core (unit-tested; no fs, no TUI)
// ---------------------------------------------------------------------------

export type RowSource = "override" | "agent" | "inherit";

export interface AgentModelRow {
	name: string;
	display: string;
	source: RowSource;
}

export interface LiteAgent {
	name: string;
	model?: string;
}

export const INHERIT_VALUE = "__inherit__";

/**
 * Resolve what each agent would actually run: settings override wins, then the
 * agent's own (frontmatter) model, then the parent session model.
 */
export function buildAgentRows(
	agents: readonly LiteAgent[],
	overrides: Readonly<Record<string, string>>,
	parentModel: string | undefined,
): AgentModelRow[] {
	return agents.map((agent) => {
		const override = overrides[agent.name];
		if (override) return { name: agent.name, display: override, source: "override" as const };
		if (agent.model) return { name: agent.name, display: agent.model, source: "agent" as const };
		return { name: agent.name, display: parentModel ?? "default", source: "inherit" as const };
	});
}

export function getUserSettingsPath(): string {
	return path.join(getAgentDir(), "settings.json");
}

export function readSettingsObject(filePath: string): Record<string, unknown> {
	if (!fs.existsSync(filePath)) return {};
	const parsed = JSON.parse(fs.readFileSync(filePath, "utf-8")) as unknown;
	if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
		throw new Error(`Settings file '${filePath}' must contain a JSON object.`);
	}
	return parsed as Record<string, unknown>;
}

export function writeSettingsObject(filePath: string, value: unknown): void {
	fs.mkdirSync(path.dirname(filePath), { recursive: true });
	fs.writeFileSync(filePath, `${JSON.stringify(value, null, 2)}\n`, "utf-8");
}

function asRecord(value: unknown): Record<string, unknown> | undefined {
	return value !== null && typeof value === "object" && !Array.isArray(value)
		? (value as Record<string, unknown>)
		: undefined;
}

/** Extract `subagents.agentOverrides.<name>.model` entries as a flat map. */
export function readModelOverrides(settings: Readonly<Record<string, unknown>>): Record<string, string> {
	const overrides = asRecord(asRecord(settings.subagents)?.agentOverrides) ?? {};
	const result: Record<string, string> = {};
	for (const [name, value] of Object.entries(overrides)) {
		const model = asRecord(value)?.model;
		if (typeof model === "string" && model.trim()) result[name] = model.trim();
	}
	return result;
}

/** Return settings with `subagents.agentOverrides.<agent>.model` set. */
export function withModelOverride(
	settings: Readonly<Record<string, unknown>>,
	agent: string,
	model: string,
): Record<string, unknown> {
	const next = structuredClone(settings) as Record<string, unknown>;
	const subagents = asRecord(next.subagents) ?? {};
	const agentOverrides = asRecord(subagents.agentOverrides) ?? {};
	const entry = asRecord(agentOverrides[agent]) ?? {};
	entry.model = model;
	agentOverrides[agent] = entry;
	subagents.agentOverrides = agentOverrides;
	next.subagents = subagents;
	return next;
}

/**
 * Return settings with the agent's model override removed, pruning
 * `agentOverrides` and `subagents` when they become empty. Returns the input
 * unchanged when there is nothing to remove.
 */
export function withoutModelOverride(
	settings: Readonly<Record<string, unknown>>,
	agent: string,
): Record<string, unknown> {
	const subagents = asRecord(settings.subagents);
	const agentOverrides = asRecord(subagents?.agentOverrides);
	const entry = asRecord(agentOverrides?.[agent]);
	if (!subagents || !agentOverrides || !entry || entry.model === undefined) {
		return settings as Record<string, unknown>;
	}
	const next = structuredClone(settings) as Record<string, unknown>;
	const nextSubagents = next.subagents as Record<string, unknown>;
	const nextOverrides = nextSubagents.agentOverrides as Record<string, unknown>;
	const nextEntry = nextOverrides[agent] as Record<string, unknown>;
	delete nextEntry.model;
	if (Object.keys(nextEntry).length === 0) delete nextOverrides[agent];
	if (Object.keys(nextOverrides).length === 0) delete nextSubagents.agentOverrides;
	if (Object.keys(nextSubagents).length === 0) delete next.subagents;
	return next;
}

export interface ThinkingEntry {
	/** Empty string = default (no level suffix). */
	value: string;
	label: string;
}

/** Thinking choices for a model: default first, then supported levels. */
export function thinkingEntries(model: ModelInfo): ThinkingEntry[] {
	const levels = getSupportedThinkingLevels(model);
	return [{ value: "", label: "Default (no level)" }, ...levels.map((level) => ({ value: level, label: level }))];
}

/** Combine a model id and a chosen level into the stored override value. */
export function combineOverride(fullId: string, level: string): string {
	return level ? `${fullId}:${level}` : fullId;
}

// ---------------------------------------------------------------------------
// TUI glue
// ---------------------------------------------------------------------------

/** Structural view of a registry model; tolerates older/newer pi versions. */
interface RegistryModelLike {
	provider: string;
	id: string;
	name?: string;
	reasoning?: boolean;
	thinkingLevelMap?: ThinkingLevelMap;
}
export interface PickerDeps {
	/** Configured lite agents (name + resolved config model) for display. */
	listAgents: (cwd: string) => LiteAgent[];
	/** Builds the one-line agent summary notified after a committed change. */
	summaryFor: (cwd: string) => string;
}

type PickerState =
	| { kind: "agents" }
	| { kind: "models"; agent: string }
	| { kind: "thinking"; agent: string; fullId: string; info: ModelInfo };

function isPrintableChar(data: string): boolean {
	return data.length === 1 && data >= " " && data !== "\x7f";
}

function isBackspace(data: string): boolean {
	return data === "\x7f" || data === "\b";
}

function renderTextTable(rows: AgentModelRow[]): string {
	return rows.map((row) => `${row.name.padEnd(16)} ${row.display}  [${row.source}]`).join("\n");
}

export function registerSubagentsPickerCommand(pi: ExtensionAPI, deps: PickerDeps): void {
	pi.registerCommand("subagents", {
		description: "Pick models and thinking levels for subagents",
		handler: async (_args: string, ctx: ExtensionCommandContext) => {
			const settingsPath = getUserSettingsPath();
			const parentModel = ctx.model ? `${ctx.model.provider}/${ctx.model.id}` : undefined;

			let settings: Record<string, unknown>;
			try {
				settings = readSettingsObject(settingsPath);
			} catch (error) {
				const message = `Cannot read ${settingsPath}: ${error instanceof Error ? error.message : String(error)}`;
				if (ctx.hasUI) ctx.ui.notify(message, "error");
				else console.error(message);
				return;
			}
			const initialOverrides = readModelOverrides(settings);

			if (ctx.mode !== "tui") {
				const rows = buildAgentRows(deps.listAgents(ctx.cwd), initialOverrides, parentModel);
				if (ctx.hasUI) ctx.ui.notify("The subagents picker needs TUI mode; current values below.", "warning");
				console.log(`${renderTextTable(rows)}\nEdit '${settingsPath}' (subagents.agentOverrides) to change.`);
				return;
			}

			// `scopedModels` exists in newer pi versions only; peer range starts earlier.
			const scoped = (ctx as ExtensionCommandContext & { scopedModels?: ReadonlyArray<{ model: RegistryModelLike }> })
				.scopedModels;
			const registryModels: RegistryModelLike[] =
				scoped && scoped.length > 0
					? scoped.map((entry) => entry.model)
					: (ctx.modelRegistry.getAvailable() as unknown as RegistryModelLike[]);
			const modelItems = new Map<string, SelectItem>();
			for (const model of registryModels) {
				const info = toModelInfo(model);
				if (modelItems.has(info.fullId)) continue;
				const name = model.name;
				modelItems.set(info.fullId, {
					value: info.fullId,
					label: info.fullId,
					description: name && name !== model.id ? name : undefined,
				});
			}
			const sortedModels = [...modelItems.values()].sort((a, b) => a.value.localeCompare(b.value));

			let overrides = initialOverrides;
			let committed = false;
			let writeError: string | undefined;

			function commitOverride(agent: string, value: string | undefined): void {
				writeError = undefined;
				try {
					const current = readSettingsObject(settingsPath);
					const next =
						value === undefined ? withoutModelOverride(current, agent) : withModelOverride(current, agent, value);
					if (next === current) return;
					writeSettingsObject(settingsPath, next);
					overrides = readModelOverrides(next);
					committed = true;
				} catch (error) {
					writeError = error instanceof Error ? error.message : String(error);
				}
			}

			await ctx.ui.custom<void>((tui, theme, _kb, done) => {
				let state: PickerState = { kind: "agents" };
				let filter = "";
				let list: SelectList = buildAgentsList();

				function selectTheme() {
					return {
						selectedPrefix: (text: string) => theme.fg("accent", text),
						selectedText: (text: string) => theme.fg("accent", text),
						description: (text: string) => theme.fg("muted", text),
						scrollInfo: (text: string) => theme.fg("dim", text),
						noMatch: (text: string) => theme.fg("warning", text),
					};
				}

				function buildAgentsList(): SelectList {
					const rows = buildAgentRows(deps.listAgents(ctx.cwd), overrides, parentModel);
					const items: SelectItem[] = rows.map((row) => ({
						value: row.name,
						label: row.name,
						description: `${row.display}  [${row.source}]`,
					}));
					const selectList = new SelectList(items, Math.min(items.length, 12), selectTheme());
					selectList.onSelect = (item) => {
						state = { kind: "models", agent: item.value };
						filter = "";
						enterState();
					};
					selectList.onCancel = () => done(undefined);
					return selectList;
				}

				function buildModelsList(agent: string): SelectList {
					const inheritItem: SelectItem = {
						value: INHERIT_VALUE,
						label: "Inherit session model",
						description: overrides[agent]
							? `clear override (${overrides[agent]})`
							: parentModel
								? `no override set (session runs ${parentModel})`
								: "no override set",
					};
					const matches = filter
						? fuzzyFilter(sortedModels, filter, (item) => `${item.value} ${item.description ?? ""}`)
						: sortedModels;
					const items = [inheritItem, ...matches];
					const selectList = new SelectList(items, Math.min(items.length, 12), selectTheme());
					selectList.onSelect = (item) => {
						if (item.value === INHERIT_VALUE) {
							commitOverride(agent, undefined);
							state = { kind: "agents" };
							enterState();
							return;
						}
						const model = registryModels.find((candidate) => {
							const info = toModelInfo(candidate);
							return info.fullId === item.value;
						});
						if (!model) return;
						state = { kind: "thinking", agent, fullId: item.value, info: toModelInfo(model) };
						enterState();
					};
					selectList.onCancel = () => {
						state = { kind: "agents" };
						enterState();
					};
					return selectList;
				}

				function buildThinkingList(agent: string, fullId: string, info: ModelInfo): SelectList {
					const entries = thinkingEntries(info);
					const items: SelectItem[] = entries.map((entry) => ({
						value: entry.value,
						label: entry.label,
						description: entry.value ? undefined : "session defaultThinkingLevel applies",
					}));
					const selectList = new SelectList(items, Math.min(items.length, 12), selectTheme());
					selectList.onSelect = (item) => {
						commitOverride(agent, combineOverride(fullId, item.value));
						state = { kind: "agents" };
						enterState();
					};
					selectList.onCancel = () => {
						state = { kind: "models", agent };
						enterState();
					};
					return selectList;
				}

				function titleFor(): string {
					switch (state.kind) {
						case "agents":
							return "Subagents — pick an agent";
						case "models":
							return `Model for ${state.agent}`;
						case "thinking":
							return `Thinking for ${state.agent} · ${state.fullId}`;
					}
				}

				function hintFor(): string {
					switch (state.kind) {
						case "agents":
							return "↑↓ navigate · enter pick · esc close";
						case "models":
							return "type to filter · ↑↓ navigate · enter pick · esc back";
						case "thinking":
							return "↑↓ navigate · enter pick · esc back";
					}
				}

				function enterState(): void {
					switch (state.kind) {
						case "agents":
							list = buildAgentsList();
							break;
						case "models":
							list = buildModelsList(state.agent);
							break;
						case "thinking":
							list = buildThinkingList(state.agent, state.fullId, state.info);
							break;
					}
					tui.requestRender();
				}

				enterState();

				return {
					render(width: number): string[] {
						const lines = [theme.fg("accent", theme.bold(titleFor()))];
						if (state.kind === "models" && filter) {
							lines.push(theme.fg("dim", `filter: ${filter}`));
						}
						lines.push(...list.render(width));
						lines.push(theme.fg("dim", hintFor()));
						return lines;
					},
					handleInput(data: string): void {
						if (state.kind === "models") {
							if (isPrintableChar(data)) {
								filter += data;
								list = buildModelsList(state.agent);
								tui.requestRender();
								return;
							}
							if (isBackspace(data) && filter.length > 0) {
								filter = filter.slice(0, -1);
								list = buildModelsList(state.agent);
								tui.requestRender();
								return;
							}
						}
						list.handleInput(data);
						tui.requestRender();
					},
					invalidate(): void {
						list.invalidate();
					},
				};
			});

			if (writeError) {
				ctx.ui.notify(`Failed to update settings: ${writeError}`, "error");
				return;
			}
			if (committed) ctx.ui.notify(`Subagents:\n${deps.summaryFor(ctx.cwd)}`, "info");
		},
	});
}
