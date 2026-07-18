import { describe, expect, it } from "vitest";
import { resolveEffectiveAcceptance } from "../src/runs/shared/acceptance.js";

describe("acceptance inference", () => {
	it.each([
		"explore",
		"review",
		"researcher",
	])("keeps read-only %s runs attested when task wording contains write or risk terms", (agentName) => {
		const acceptance = resolveEffectiveAcceptance({
			explicit: "attested",
			agentName,
			task: "Research security fixes and release updates.",
		});

		expect(acceptance.level).toBe("attested");
		expect(acceptance.evidence).toEqual(["review-findings", "residual-risks"]);
	});

	it("still requires changed-file evidence for implementation runs", () => {
		const acceptance = resolveEffectiveAcceptance({
			explicit: "attested",
			agentName: "general-purpose",
			task: "Implement the requested fix.",
		});

		expect(acceptance.level).toBe("checked");
		expect(acceptance.evidence).toContain("changed-files");
	});
});
