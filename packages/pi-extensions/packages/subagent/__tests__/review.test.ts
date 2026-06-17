import { describe, expect, it } from "vitest";
import { createReviewAgent } from "../extensions/agents/review.js";

describe("createReviewAgent", () => {
	it("configures a read-only compact subagent", () => {
		const agent = createReviewAgent();

		expect(agent.name).toBe("review");
		expect(agent.mode).toBe("subagent");
		expect(agent.compactLivePreview).toBe(true);
		expect(agent.tools.write).toBe(false);
		expect(agent.tools.edit).toBe(false);
		expect(agent.tools.subagent).toBe(false);
	});

	it("pushes the agent toward high-confidence actionable findings", () => {
		const agent = createReviewAgent();

		expect(agent.systemPrompt).toContain("Report only issues that are high-confidence and actionable");
		expect(agent.systemPrompt).toContain("Prefer no findings over noisy findings");
		expect(agent.systemPrompt).toContain("You are at least 80% confident it is real");
		expect(agent.systemPrompt).toContain("No high-confidence findings.");
		expect(agent.systemPrompt).toContain("Do not report:");
		expect(agent.systemPrompt).toContain("Theoretical edge cases without a plausible path in this codebase");
	});
});
