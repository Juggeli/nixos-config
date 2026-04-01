import { beforeEach, describe, expect, it, vi } from "vitest";
import subagentExtension from "../extensions/index.js";

interface RegisteredTool {
	name: string;
	label: string;
	description: string;
	promptSnippet?: string;
	promptGuidelines?: string[];
	parameters: unknown;
	renderCall?: (args: Record<string, any>, theme: Record<string, any>) => { render: (width: number) => string[] };
	renderResult?: (
		result: Record<string, any>,
		state: Record<string, any>,
		theme: Record<string, any>,
	) => { render: (width: number) => string[] };
	execute?: (...args: any[]) => Promise<any>;
}

describe("subagent extension registration", () => {
	let registeredTool: RegisteredTool;

	beforeEach(() => {
		registeredTool = undefined as unknown as RegisteredTool;

		const mockPi = {
			registerTool: vi.fn((tool: RegisteredTool) => {
				registeredTool = tool;
			}),
			registerCommand: vi.fn(),
			on: vi.fn(),
		};

		subagentExtension(mockPi as unknown as Parameters<typeof subagentExtension>[0]);
	});

	it("registers the subagent tool", () => {
		expect(registeredTool.name).toBe("subagent");
		expect(registeredTool.label).toBe("Subagent");
		expect(registeredTool.description).toContain("Built-in agents: explore, librarian.");
		expect(registeredTool.description).not.toContain("call without parameters");
	});

	it("has a prompt snippet for the system prompt", () => {
		expect(registeredTool.promptSnippet).toBe(
			"Use subagent for focused investigation: explore for this repo, librarian for external docs/code",
		);
	});

	it("has prompt guidelines covering agent usage", () => {
		expect(registeredTool.promptGuidelines).toBeDefined();
		expect(registeredTool.promptGuidelines).toContain(
			"Treat explore and librarian as read-only peer tools for research, not as fallback after you have already done the same search yourself.",
		);
		expect(registeredTool.promptGuidelines).toContain(
			"Use the explore agent for read-only codebase search, architecture tracing, finding files, symbols, usages, and git history in the current repository.",
		);
		expect(registeredTool.promptGuidelines).toContain(
			"Use direct tools instead of explore when you already know the exact file or exact command you need and delegation would add overhead.",
		);
		expect(registeredTool.promptGuidelines).toContain(
			"Use the librarian agent for external libraries, frameworks, API docs, upstream source code, GitHub issues, and evidence-backed research outside the local repo.",
		);
		expect(registeredTool.promptGuidelines).toContain(
			"Prefer tasks[] when you have multiple independent search angles or questions to ask at once.",
		);
		expect(registeredTool.promptGuidelines).toContain(
			"Use tasks[] to gather several independent findings in one subagent call instead of making multiple separate subagent calls.",
		);
		expect(registeredTool.promptGuidelines).toContain(
			"Use session to resume an existing subagent conversation for follow-up questions, refinements, or retrying with the same context instead of starting over.",
		);
	});

	it("omits task previews in compact mode agents", () => {
		const theme = {
			fg: (_color: string, text: string) => text,
			bold: (text: string) => text,
		};

		const rendered = registeredTool
			.renderCall?.(
				{
					agent: "explore",
					task: "Explore this NixOS/dotfiles repository. Find:\n1. Top-level modules\n2. Shared lib helpers\n3. Secrets handling",
				},
				theme,
			)
			.render(120)
			.join("\n");

		expect(rendered).toContain("subagent explore");
		expect(rendered).not.toContain("Explore this NixOS/dotfiles repository. Find:");
		expect(rendered).not.toContain("1. Top-level modules");
		expect(rendered).not.toContain("...");
	});

	it("returns an error instead of listing agents when called without a mode", async () => {
		const result = await registeredTool.execute?.("tool-1", {}, undefined, undefined, {});

		expect(result?.isError).toBe(true);
		expect(result?.content?.[0]?.text).toContain("Missing parameters. Use agent + task, or tasks[]");
		expect(result?.content?.[0]?.text).toContain('"explore"');
		expect(result?.content?.[0]?.text).toContain('"librarian"');
	});

	it("shows more of the final answer for compact agents in collapsed results", () => {
		const theme = {
			fg: (_color: string, text: string) => text,
			bold: (text: string) => text,
		};

		const rendered = registeredTool
			.renderResult?.(
				{
					content: [{ type: "text", text: "unused" }],
					details: {
						mode: "single",
						results: [
							{
								agent: "explore",
								task: "Inspect repo",
								exitCode: 0,
								compactLivePreview: true,
								usage: {
									input: 0,
									output: 0,
									cacheRead: 0,
									cacheWrite: 0,
									cost: 0,
									turns: 1,
									contextTokens: 0,
								},
								messages: [
									{
										role: "assistant",
										content: [
											{
												type: "text",
												text: "Answer line 1\nAnswer line 2\nAnswer line 3\nAnswer line 4\nAnswer line 5\nAnswer line 6\nAnswer line 7",
											},
										],
									},
								],
							},
						],
					},
				},
				{ expanded: false, isPartial: false },
				theme,
			)
			.render(120)
			.join("\n");

		expect(rendered).toContain("Answer line 6");
		expect(rendered).not.toContain("Answer line 7");
		expect(rendered).toContain("(Ctrl+O to expand)");
	});

	it("labels aggregate usage in collapsed parallel results", () => {
		const theme = {
			fg: (_color: string, text: string) => text,
			bold: (text: string) => text,
		};

		const rendered = registeredTool
			.renderResult?.(
				{
					content: [{ type: "text", text: "unused" }],
					details: {
						mode: "parallel",
						results: [
							{
								agent: "explore",
								task: "Inspect repo",
								exitCode: 0,
								usage: {
									input: 100,
									output: 25,
									cacheRead: 0,
									cacheWrite: 0,
									cost: 0.01,
									turns: 2,
									contextTokens: 0,
								},
								messages: [{ role: "assistant", content: [{ type: "text", text: "Answer one" }] }],
							},
							{
								agent: "explore",
								task: "Inspect repo again",
								exitCode: 0,
								usage: {
									input: 200,
									output: 50,
									cacheRead: 0,
									cacheWrite: 0,
									cost: 0.02,
									turns: 3,
									contextTokens: 0,
								},
								messages: [{ role: "assistant", content: [{ type: "text", text: "Answer two" }] }],
							},
						],
					},
				},
				{ expanded: false, isPartial: false },
				theme,
			)
			.render(120)
			.join("\n");

		expect(rendered).toContain("Total:");
		expect(rendered).toContain("5 turns");
		expect(rendered).not.toContain("ctx:");
	});
});
