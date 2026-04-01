import { describe, expect, it } from "vitest";
import {
	createToolCallSignature,
	detectTextLoop,
	detectToolLoop,
	recordTextDelta,
	recordToolCall,
	type TextDeltaWindow,
	type ToolCallWindow,
} from "../extensions/loop-detector.js";

describe("createToolCallSignature", () => {
	it("sorts object keys so equivalent calls match", () => {
		expect(createToolCallSignature("read", { path: "a.ts", offset: 10 })).toBe(
			createToolCallSignature("read", { offset: 10, path: "a.ts" }),
		);
	});

	it("returns the bare tool name when args are empty", () => {
		expect(createToolCallSignature("ls", {})).toBe("ls");
	});
});

describe("detectToolLoop", () => {
	it("does not trigger for varied tool calls", () => {
		let window: ToolCallWindow | undefined;
		window = recordToolCall(window, "find", { pattern: "*.nix" });
		window = recordToolCall(window, "read", { path: "flake.nix" });
		window = recordToolCall(window, "grep", { pattern: "imports", path: "." });

		expect(detectToolLoop(window).triggered).toBe(false);
	});

	it("triggers when the same tool call repeats too many times", () => {
		let window: ToolCallWindow | undefined;
		for (let i = 0; i < 8; i++) {
			window = recordToolCall(window, "read", { path: "flake.nix" });
		}

		expect(detectToolLoop(window)).toMatchObject({
			triggered: true,
			toolName: "read",
			repeatedCount: 8,
		});
	});

	it("does not trigger for the same tool with different args", () => {
		let window: ToolCallWindow | undefined;
		for (let i = 0; i < 8; i++) {
			window = recordToolCall(window, "read", { path: `file-${i}.nix` });
		}

		expect(detectToolLoop(window).triggered).toBe(false);
	});

	it("triggers when total tool calls exceed the limit", () => {
		let window: ToolCallWindow | undefined;
		for (let i = 0; i < 49; i++) {
			window = recordToolCall(window, "read", { path: `file-${i}.nix` });
		}

		expect(detectToolLoop(window)).toMatchObject({
			triggered: true,
			reason: "Detected runaway subagent loop: exceeded 48 tool calls without finishing.",
		});
	});
});

describe("detectTextLoop", () => {
	it("ignores whitespace-only chunks", () => {
		let window: TextDeltaWindow | undefined;
		window = recordTextDelta(window, " ");
		window = recordTextDelta(window, "\n");

		expect(window).toBeUndefined();
	});

	it("triggers on repeated single-character output", () => {
		let window: TextDeltaWindow | undefined;
		for (let i = 0; i < 32; i++) {
			window = recordTextDelta(window, "a");
		}

		expect(detectTextLoop(window)).toMatchObject({
			triggered: true,
			repeatedChunk: "a",
			repeatedCount: 32,
		});
	});

	it("triggers on repeated phrase output", () => {
		let window: TextDeltaWindow | undefined;
		for (let i = 0; i < 12; i++) {
			window = recordTextDelta(window, "same phrase");
		}

		expect(detectTextLoop(window)).toMatchObject({
			triggered: true,
			repeatedChunk: "same phrase",
			repeatedCount: 12,
		});
	});

	it("does not trigger for changing text chunks", () => {
		let window: TextDeltaWindow | undefined;
		for (const chunk of ["alpha", "beta", "gamma", "delta"]) {
			window = recordTextDelta(window, chunk);
		}

		expect(detectTextLoop(window).triggered).toBe(false);
	});
});
