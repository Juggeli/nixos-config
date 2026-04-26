import fs from "node:fs";
import path from "node:path";
import { afterEach, describe, expect, it } from "vitest";
// @ts-expect-error
import { syncProviderModels } from "../sync-models.mjs";

const TEST_AGENT_DIR = "/tmp/pi-model-sync-test";

function readModelsJson() {
	return JSON.parse(fs.readFileSync(path.join(TEST_AGENT_DIR, "models.json"), "utf-8")) as {
		providers: Record<string, { models: Array<{ id: string }> }>;
	};
}

describe("syncProviderModels", () => {
	afterEach(() => {
		fs.rmSync(TEST_AGENT_DIR, { recursive: true, force: true });
	});

	it("syncs all configured provider syncers by default", async () => {
		fs.mkdirSync(TEST_AGENT_DIR, { recursive: true });

		await syncProviderModels({
			agentDir: TEST_AGENT_DIR,
			fetchFn: async (url: string, _options?: RequestInit) => {
				if (url.includes("/api/tags")) {
					return {
						ok: true,
						json: async () => ({
							models: [{ name: "gemma3", model: "gemma3:27b" }],
						}),
					} as Response;
				}
				if (url.includes("/api/show")) {
					return {
						ok: true,
						json: async () => ({
							capabilities: ["completion", "vision"],
							model_info: { "gemma3.context_length": 131072, "general.parameter_count": 27000000000 },
						}),
					} as Response;
				}
				return { ok: false } as Response;
			},
		});

		expect(readModelsJson().providers.ollama.models).toEqual(
			expect.arrayContaining([expect.objectContaining({ id: "gemma3:27b" })]),
		);
	});

	it("skips already configured providers when ifMissing is enabled", async () => {
		fs.mkdirSync(TEST_AGENT_DIR, { recursive: true });
		fs.writeFileSync(
			path.join(TEST_AGENT_DIR, "models.json"),
			JSON.stringify({
				providers: {
					ollama: {
						baseUrl: "https://ollama.com/v1",
						apiKey: "OLLAMA_API_KEY",
						api: "openai-completions",
						models: [{ id: "llama3.2:latest" }],
					},
				},
			}),
		);

		const result = await syncProviderModels({
			agentDir: TEST_AGENT_DIR,
			ifMissing: true,
			fetchFn: async () => {
				throw new Error("fetch should not be called");
			},
		});

		expect(result).toEqual({ updated: false, syncedProviders: [] });
		expect(readModelsJson().providers.ollama.models).toEqual([{ id: "llama3.2:latest" }]);
	});
});
