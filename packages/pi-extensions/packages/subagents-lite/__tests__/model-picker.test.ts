import { describe, expect, it } from "vitest";
import {
	buildAgentRows,
	combineOverride,
	readModelOverrides,
	thinkingEntries,
	withModelOverride,
	withoutModelOverride,
} from "../extensions/subagents-picker.js";

describe("buildAgentRows", () => {
	const agents = [{ name: "explore" }, { name: "review", model: "frontmatter/model" }, { name: "researcher" }];

	it("prefers settings override, then agent model, then parent session model", () => {
		const rows = buildAgentRows(agents, { explore: "picked/model:high" }, "parent/model");

		expect(rows).toEqual([
			{ name: "explore", display: "picked/model:high", source: "override" },
			{ name: "review", display: "frontmatter/model", source: "agent" },
			{ name: "researcher", display: "parent/model", source: "inherit" },
		]);
	});

	it("falls back to 'default' when inheriting without a parent model", () => {
		const rows = buildAgentRows([{ name: "explore" }], {}, undefined);

		expect(rows[0]).toEqual({ name: "explore", display: "default", source: "inherit" });
	});
});

describe("settings override round-trip", () => {
	it("sets a nested override and preserves unrelated keys", () => {
		const settings = { theme: "dark", subagents: { modelScope: { enforce: false } } };

		const next = withModelOverride(settings, "review", "anthropic/claude-sonnet-4:high");

		expect(next).toEqual({
			theme: "dark",
			subagents: {
				modelScope: { enforce: false },
				agentOverrides: { review: { model: "anthropic/claude-sonnet-4:high" } },
			},
		});
		expect(settings).toEqual({ theme: "dark", subagents: { modelScope: { enforce: false } } });
	});

	it("keeps other fields on an existing override entry", () => {
		const settings = { subagents: { agentOverrides: { explore: { somethingElse: true, model: "old/model" } } } };

		const next = withModelOverride(settings, "explore", "new/model");

		expect(next.subagents).toEqual({ agentOverrides: { explore: { somethingElse: true, model: "new/model" } } });
	});

	it("clears an override and prunes empty containers", () => {
		const settings = {
			theme: "dark",
			subagents: { agentOverrides: { explore: { model: "old/model" } } },
		};

		const next = withoutModelOverride(settings, "explore");

		expect(next).toEqual({ theme: "dark" });
	});

	it("keeps sibling subagents keys when pruning", () => {
		const settings = {
			subagents: {
				modelScope: { enforce: true, allow: ["deepseek/*"] },
				agentOverrides: { explore: { model: "old/model" } },
			},
		};

		const next = withoutModelOverride(settings, "explore");

		expect(next).toEqual({ subagents: { modelScope: { enforce: true, allow: ["deepseek/*"] } } });
	});

	it("returns the same object when there is nothing to clear", () => {
		const settings = { theme: "dark" };

		expect(withoutModelOverride(settings, "explore")).toBe(settings);
	});

	it("reads overrides back as a flat map, ignoring malformed entries", () => {
		const settings = {
			subagents: {
				agentOverrides: {
					explore: { model: "  picked/model:high  " },
					review: { model: "" },
					researcher: "not-an-object",
					"general-purpose": { model: "other/model" },
				},
			},
		};

		expect(readModelOverrides(settings)).toEqual({
			explore: "picked/model:high",
			"general-purpose": "other/model",
		});
	});
});

describe("thinkingEntries", () => {
	it("offers the default plus all levels for models without a thinking map", () => {
		const entries = thinkingEntries({ provider: "p", id: "m", fullId: "p/m" });

		expect(entries.map((entry) => entry.value)).toEqual(["", "off", "minimal", "low", "medium", "high", "xhigh"]);
	});

	it("offers only 'off' for non-reasoning models", () => {
		const entries = thinkingEntries({ provider: "p", id: "m", fullId: "p/m", reasoning: false });

		expect(entries.map((entry) => entry.value)).toEqual(["", "off"]);
	});

	it("respects the thinking level map, hiding null entries and unlisted xhigh", () => {
		const entries = thinkingEntries({
			provider: "p",
			id: "m",
			fullId: "p/m",
			thinkingLevelMap: { off: null, minimal: null, low: "low-budget", medium: null, high: "high-budget" },
		});

		expect(entries.map((entry) => entry.value)).toEqual(["", "low", "high"]);
	});
});

describe("combineOverride", () => {
	it("writes bare model id for the default level", () => {
		expect(combineOverride("p/m", "")).toBe("p/m");
	});

	it("appends the chosen level", () => {
		expect(combineOverride("p/m", "high")).toBe("p/m:high");
	});
});
