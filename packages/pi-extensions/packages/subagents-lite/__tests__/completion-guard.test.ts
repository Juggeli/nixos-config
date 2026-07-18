import { describe, expect, it } from "vitest";
import { expectsImplementationMutation } from "../src/runs/shared/completion-guard.js";

describe("completion mutation intent", () => {
	it("requires mutations only for general-purpose implementation tasks", () => {
		expect(expectsImplementationMutation("general-purpose", "Implement the requested fix.")).toBe(true);
		expect(expectsImplementationMutation("general-purpose", "Analyze the behavior and report findings.")).toBe(false);
	});

	it("recognizes explicit non-edit constraints", () => {
		expect(expectsImplementationMutation("general-purpose", "Do not inspect or modify files.")).toBe(false);
		expect(expectsImplementationMutation("general-purpose", "Review the implementation without changing code.")).toBe(
			false,
		);
		expect(expectsImplementationMutation("general-purpose", "Investigate only; no file changes.")).toBe(false);
	});
});
