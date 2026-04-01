import { describe, expect, it } from "vitest";
import {
	createReadOnlyBashTool,
	createResearchBashTool,
	validateReadOnlyBashCommand,
	validateResearchBashCommand,
} from "../extensions/read-only-bash.js";

describe("validateReadOnlyBashCommand", () => {
	it("allows read-only git commands", () => {
		expect(validateReadOnlyBashCommand("git log --oneline -n 5")).toEqual({ allowed: true });
		expect(validateReadOnlyBashCommand("git blame packages/coding-agent/src/main.ts")).toEqual({ allowed: true });
		expect(validateReadOnlyBashCommand("git config --get remote.origin.url")).toEqual({ allowed: true });
	});

	it("blocks command chaining", () => {
		const result = validateReadOnlyBashCommand("git status; touch /tmp/pwned");
		expect(result.allowed).toBe(false);
		expect(result.reason).toContain("chaining");
	});

	it("blocks redirection", () => {
		const result = validateReadOnlyBashCommand("echo hello > /tmp/out.txt");
		expect(result.allowed).toBe(false);
		expect(result.reason).toContain("destructive");
	});

	it("blocks git write commands", () => {
		const result = validateReadOnlyBashCommand("git commit -m 'nope'");
		expect(result.allowed).toBe(false);
		expect(result.reason).toContain("destructive");
	});

	it("blocks commands not on the allowlist", () => {
		const result = validateReadOnlyBashCommand("python -c 'print(1)'");
		expect(result.allowed).toBe(false);
		expect(result.reason).toContain("allowlist");
	});
});

describe("createReadOnlyBashTool", () => {
	it("rejects blocked commands before execution", async () => {
		const tool = createReadOnlyBashTool(process.cwd());
		await expect(tool.execute("test", { command: "echo hello > /tmp/read-only-bash-test.txt" })).rejects.toThrow(
			"Command blocked by read-only bash policy",
		);
	});
});

describe("validateResearchBashCommand", () => {
	it("allows repo cloning into /tmp", () => {
		expect(validateResearchBashCommand("gh repo clone owner/repo /tmp/repo -- --depth=1")).toEqual({
			allowed: true,
		});
		expect(
			validateResearchBashCommand("git clone --depth=1 https://github.com/owner/repo.git /tmp/repo"),
		).toEqual({ allowed: true });
	});

	it("allows git inspection inside /tmp clones", () => {
		expect(validateResearchBashCommand("git -C /tmp/repo rev-parse HEAD")).toEqual({ allowed: true });
		expect(validateResearchBashCommand("git -C /tmp/repo show HEAD~1")).toEqual({ allowed: true });
	});

	it("allows GitHub metadata queries", () => {
		expect(validateResearchBashCommand("gh search issues query words")).toEqual({ allowed: true });
		expect(validateResearchBashCommand("gh pr view 123 --repo owner/repo")).toEqual({ allowed: true });
	});

	it("blocks clones outside /tmp", () => {
		const result = validateResearchBashCommand("gh repo clone owner/repo ./repo -- --depth=1");
		expect(result.allowed).toBe(false);
	});
});

describe("createResearchBashTool", () => {
	it("rejects writes to the user repo before execution", async () => {
		const tool = createResearchBashTool(process.cwd());
		await expect(tool.execute("test", { command: "touch ./should-not-write" })).rejects.toThrow(
			"Command blocked by research bash policy",
		);
	});
});
