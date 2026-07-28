import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { afterAll, beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import fileSearchExtension, { buildFdArgs } from "../extensions/index.js";

// Mock dependencies
vi.mock("@earendil-works/pi-tui", () => ({
	Text: vi.fn().mockImplementation(function (this: { text: string }, text: string) {
		this.text = text;
	}),
	truncateToWidth: vi.fn((s: string) => s),
}));

interface ToolResult {
	content: Array<{ type: string; text: string }>;
	details?: {
		error?: string;
		lineCount?: number;
		truncated?: boolean;
		fullOutputPath?: string;
	};
}

interface RegisteredTool {
	name: string;
	label: string;
	description: string;
	promptSnippet?: string;
	promptGuidelines?: string[];
	parameters: unknown;
	execute: (
		toolCallId: string,
		params: Record<string, unknown>,
		signal?: AbortSignal,
		onUpdate?: unknown,
		ctx?: { cwd?: string },
	) => Promise<ToolResult>;
	renderCall: (args: Record<string, unknown>, theme: Record<string, unknown>) => { text: string };
	renderResult: (result: ToolResult, options: unknown, theme: Record<string, unknown>) => { text: string };
}

const mockTheme = {
	bold: (s: string) => s,
	fg: (_color: string, s: string) => s,
};

describe("file-search extension", () => {
	let registeredTools: Map<string, RegisteredTool>;

	beforeEach(() => {
		vi.clearAllMocks();
		registeredTools = new Map();
		const mockPi = {
			registerTool: vi.fn((tool: RegisteredTool) => {
				registeredTools.set(tool.name, tool);
			}),
			on: vi.fn(),
		};
		fileSearchExtension(mockPi as unknown as Parameters<typeof fileSearchExtension>[0]);
	});

	describe("tool registration", () => {
		it("registers fd tool", () => {
			const tool = registeredTools.get("fd");
			expect(tool).toBeDefined();
			expect(tool?.label).toBe("Find Files");
		});

		it("does not register rg tool", () => {
			expect(registeredTools.has("rg")).toBe(false);
		});
	});

	describe("buildFdArgs", () => {
		it("builds default args with empty pattern after separator", () => {
			expect(buildFdArgs({})).toEqual(["--color=never", "--max-results", "1000", "--", ""]);
		});

		it("maps all parameters to flags", () => {
			expect(
				buildFdArgs({
					pattern: "index",
					path: "src",
					type: "file",
					extension: ".ts",
					glob: true,
					hidden: true,
					max_depth: 3,
					limit: 50,
				}),
			).toEqual([
				"--color=never",
				"--hidden",
				"--glob",
				"--type",
				"f",
				"--extension",
				"ts",
				"--max-depth",
				"3",
				"--max-results",
				"50",
				"--",
				"index",
				"src",
			]);
		});

		it("keeps flag-like patterns behind the separator", () => {
			const args = buildFdArgs({ pattern: "--version" });
			expect(args.slice(args.indexOf("--"))).toEqual(["--", "--version"]);
		});

		it("clamps limit and max_depth", () => {
			const args = buildFdArgs({ limit: 99999, max_depth: 999 });
			expect(args).toContain("10000");
			expect(args).toContain("64");
		});

		it("strips @ prefix and drops empty paths", () => {
			expect(buildFdArgs({ path: "@src" })).toContain("src");
			expect(buildFdArgs({ path: "  " })).toEqual(["--color=never", "--max-results", "1000", "--", ""]);
		});
	});

	describe("execute", () => {
		let workDir: string;

		beforeAll(async () => {
			workDir = await mkdtemp(join(tmpdir(), "pi-file-search-test-"));
			await writeFile(join(workDir, "alpha.ts"), "const needle = 1;\n");
			await writeFile(join(workDir, "beta.md"), "no matches here\n");
		});

		afterAll(async () => {
			await rm(workDir, { recursive: true, force: true });
		});

		it("fd finds files by extension", async () => {
			const tool = registeredTools.get("fd");
			const result = await tool?.execute("t1", { extension: "ts" }, undefined, undefined, {
				cwd: workDir,
			});
			expect(result?.details?.error).toBeUndefined();
			expect(result?.content[0]?.text).toContain("alpha.ts");
			expect(result?.content[0]?.text).not.toContain("beta.md");
		});

		it("fd reports no files found", async () => {
			const tool = registeredTools.get("fd");
			const result = await tool?.execute("t2", { extension: "rs" }, undefined, undefined, {
				cwd: workDir,
			});
			expect(result?.content[0]?.text).toBe("No files found");
			expect(result?.details?.lineCount).toBe(0);
		});

		it("aborts when the signal is already aborted", async () => {
			const tool = registeredTools.get("fd");
			const controller = new AbortController();
			controller.abort();
			const result = await tool?.execute("t3", { pattern: "alpha" }, controller.signal, undefined, {
				cwd: workDir,
			});
			expect(result?.details?.error).toBe("Search was cancelled");
		});
	});

	describe("rendering", () => {
		it("renderCall shows fd pattern and flags", () => {
			const tool = registeredTools.get("fd");
			const rendered = tool?.renderCall({ pattern: "index", type: "file", hidden: true }, mockTheme);
			expect(rendered?.text).toContain('fd "index"');
			expect(rendered?.text).toContain("type=file");
			expect(rendered?.text).toContain("hidden");
		});

		it("renderCall shows (all) when fd has no pattern", () => {
			const tool = registeredTools.get("fd");
			const rendered = tool?.renderCall({}, mockTheme);
			expect(rendered?.text).toContain("(all)");
		});

		it("renderResult pluralizes counts", () => {
			const tool = registeredTools.get("fd");
			const one = tool?.renderResult(
				{ content: [{ type: "text", text: "a" }], details: { lineCount: 1 } },
				{},
				mockTheme,
			);
			expect(one?.text).toContain("1 entry");
			const many = tool?.renderResult(
				{ content: [{ type: "text", text: "a\nb" }], details: { lineCount: 2 } },
				{},
				mockTheme,
			);
			expect(many?.text).toContain("2 entries");
		});

		it("renderResult shows errors", () => {
			const tool = registeredTools.get("fd");
			const rendered = tool?.renderResult(
				{ content: [{ type: "text", text: "Error: boom" }], details: { error: "boom" } },
				{},
				mockTheme,
			);
			expect(rendered?.text).toContain("Error: boom");
		});
	});
});
