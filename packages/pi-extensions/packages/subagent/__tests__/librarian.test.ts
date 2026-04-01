import { describe, expect, it } from "vitest";
import { resolveTools } from "../extensions/tool-restrictions.js";
import { createLibrarianAgent } from "../extensions/agents/librarian.js";

describe("createLibrarianAgent", () => {
	it("enforces research bash policy", () => {
		const agent = createLibrarianAgent();
		expect(agent.bashPolicy).toBe("research");
	});

	it("uses a streamlined research prompt without forced analysis tags", () => {
		const agent = createLibrarianAgent();
		expect(agent.systemPrompt).not.toContain("<analysis>");
		expect(agent.systemPrompt).toContain("Do not dump hidden reasoning or planning.");
	});

	it("describes repo cloning and primary-source research", () => {
		const agent = createLibrarianAgent();
		expect(agent.systemPrompt).toContain("Prefer official docs, upstream source code, release notes, issues, and PRs");
		expect(agent.systemPrompt).toContain("You may clone external repositories into `/tmp` for inspection");
	});

	it("blocks destructive bash commands", async () => {
		const agent = createLibrarianAgent();
		const tools = resolveTools(process.cwd(), agent.tools, agent.bashPolicy);
		const bashTool = tools.find((tool) => tool.name === "bash");
		if (!bashTool) throw new Error("bash tool was not resolved");

		await expect(bashTool.execute("test", { command: "touch /tmp/librarian-should-not-write" })).rejects.toThrow(
			"Command blocked by research bash policy",
		);
	});

	it("allows safe research bash commands", async () => {
		const agent = createLibrarianAgent();
		const tools = resolveTools(process.cwd(), agent.tools, agent.bashPolicy);
		const bashTool = tools.find((tool) => tool.name === "bash");
		if (!bashTool) throw new Error("bash tool was not resolved");

		await expect(bashTool.execute("test", { command: "pwd" })).resolves.toBeDefined();
	});
});
