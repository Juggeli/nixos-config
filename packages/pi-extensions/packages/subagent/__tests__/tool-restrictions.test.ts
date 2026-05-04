import { describe, expect, it } from "vitest";
import {
	ALL_TOOL_NAMES,
	EXPLORE_RESTRICTIONS,
	resolveBuiltinToolNames,
	resolveCustomBashTool,
	resolveToolNames,
	SUBAGENT_DEFAULTS,
} from "../extensions/tool-restrictions.js";

describe("resolveToolNames", () => {
	it("returns all tools when restrictions are empty", () => {
		expect(resolveToolNames({})).toEqual([...ALL_TOOL_NAMES]);
	});

	it("excludes tools set to false", () => {
		const result = resolveToolNames({ write: false, edit: false });
		expect(result).not.toContain("write");
		expect(result).not.toContain("edit");
		expect(result).toContain("read");
		expect(result).toContain("bash");
	});

	it("includes tools set to true", () => {
		const result = resolveToolNames({ read: true, bash: true, write: false });
		expect(result).toContain("read");
		expect(result).toContain("bash");
		expect(result).not.toContain("write");
	});

	it("ignores unknown tool names in restrictions", () => {
		const result = resolveToolNames({ unknownTool: false });
		expect(result).toEqual([...ALL_TOOL_NAMES]);
	});

	it("returns empty array when all tools denied", () => {
		const allDenied: Record<string, boolean> = {};
		for (const name of ALL_TOOL_NAMES) allDenied[name] = false;
		expect(resolveToolNames(allDenied)).toEqual([]);
	});
});

describe("SUBAGENT_DEFAULTS", () => {
	it("denies subagent tool", () => {
		expect(SUBAGENT_DEFAULTS.subagent).toBe(false);
	});

	it("allows all built-in tools (subagent is not a built-in)", () => {
		const result = resolveToolNames(SUBAGENT_DEFAULTS);
		expect(result).toEqual([...ALL_TOOL_NAMES]);
	});
});

describe("EXPLORE_RESTRICTIONS", () => {
	it("denies write, edit, and subagent", () => {
		expect(EXPLORE_RESTRICTIONS.write).toBe(false);
		expect(EXPLORE_RESTRICTIONS.edit).toBe(false);
		expect(EXPLORE_RESTRICTIONS.subagent).toBe(false);
	});

	it("allows read-only tools", () => {
		const result = resolveToolNames(EXPLORE_RESTRICTIONS);
		expect(result).toContain("read");
		expect(result).toContain("grep");
		expect(result).toContain("find");
		expect(result).toContain("ls");
		expect(result).toContain("bash");
		expect(result).not.toContain("write");
		expect(result).not.toContain("edit");
	});
});

describe("resolveBuiltinToolNames", () => {
	it("excludes bash when bash policy is non-default", () => {
		const names = resolveBuiltinToolNames(EXPLORE_RESTRICTIONS, "read-only");
		expect(names).not.toContain("bash");
		expect(names).toContain("read");
	});

	it("keeps bash when bash policy is default", () => {
		const names = resolveBuiltinToolNames(EXPLORE_RESTRICTIONS, "default");
		expect(names).toContain("bash");
	});
});

describe("resolveCustomBashTool", () => {
	it("returns a custom bash tool for read-only policy", async () => {
		const tool = resolveCustomBashTool(process.cwd(), EXPLORE_RESTRICTIONS, "read-only");
		if (!tool) throw new Error("expected custom bash tool");
		expect(tool.name).toBe("bash");
		await expect(tool.execute("test", { command: "touch /tmp/should-not-exist" }, undefined, undefined, {} as never))
			.rejects.toThrow("Command blocked by read-only bash policy");
	});

	it("returns undefined for default policy", () => {
		const tool = resolveCustomBashTool(process.cwd(), EXPLORE_RESTRICTIONS, "default");
		expect(tool).toBeUndefined();
	});

	it("returns undefined when bash is denied", () => {
		const tool = resolveCustomBashTool(process.cwd(), { bash: false }, "read-only");
		expect(tool).toBeUndefined();
	});
});
