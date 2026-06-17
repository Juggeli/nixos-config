import { describe, expect, it } from "vitest";
import { createLibrarianAgent } from "../extensions/agents/librarian.js";

describe("createLibrarianAgent", () => {
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
});
