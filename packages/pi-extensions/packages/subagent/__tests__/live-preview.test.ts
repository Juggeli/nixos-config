import { describe, expect, it } from "vitest";
import { buildLivePreviewText } from "../extensions/index.js";
import { emptyUsage } from "../extensions/types.js";

describe("buildLivePreviewText", () => {
	it("renders a plain rolling activity feed", () => {
		const text = buildLivePreviewText({
			agent: "explore",
			task: "Inspect the repo",
			exitCode: -1,
			messages: [],
			usage: emptyUsage(),
			recentActivityLines: [
				{ key: "thinking:0", text: "Thinking line one" },
				{ key: "thinking:1", text: "Thinking line two" },
				{ key: "tool-1", text: "→ read ~/src/pi-mono/packages/coding-agent/src/index.ts" },
				{ key: "output:0", text: "First output line" },
				{ key: "output:1", text: "Second output line" },
			],
		});

		const lines = text.split("\n");
		expect(lines).toHaveLength(5);
		expect(lines[0]).toContain("Thinking line one");
		expect(lines[1]).toContain("Thinking line two");
		expect(lines[2]).toContain("→ read");
		expect(lines[3]).toContain("First output line");
		expect(lines[4]).toContain("Second output line");
	});

	it("renders only the latest tool line in compact mode", () => {
		const text = buildLivePreviewText({
			agent: "explore",
			task: "Inspect the repo",
			exitCode: -1,
			messages: [],
			usage: emptyUsage(),
			compactLivePreview: true,
			recentActivityLines: [
				{ key: "thinking:0", text: "Thinking line one" },
				{ key: "tool", text: "→ read ~/src/pi-mono/packages/coding-agent/src/index.ts" },
				{ key: "output:0", text: "First output line" },
			],
		});

		expect(text).toBe("→ read ~/src/pi-mono/packages/coding-agent/src/index.ts");
	});
});
