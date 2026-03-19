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
		await syncProviderModels({
			agentDir: TEST_AGENT_DIR,
			fetchFn: async () =>
				({
					ok: true,
					json: async () => ({
						data: [
							{
								id: "hf:MiniMaxAI/MiniMax-M2.5",
								hugging_face_id: "MiniMaxAI/MiniMax-M2.5",
								name: "MiniMax M2.5",
								input_modalities: ["text"],
								context_length: 128000,
								max_output_length: 32768,
								pricing: { prompt: "$0.55", completion: "$2.19" },
								supported_features: ["reasoning", "tools"],
								always_on: true,
							},
						],
					}),
				}) as Response,
		});

		expect(readModelsJson().providers.synthetic.models).toEqual(
			expect.arrayContaining([expect.objectContaining({ id: "hf:MiniMaxAI/MiniMax-M2.5" })]),
		);
	});

	it("skips already configured providers when ifMissing is enabled", async () => {
		fs.mkdirSync(TEST_AGENT_DIR, { recursive: true });
		fs.writeFileSync(
			path.join(TEST_AGENT_DIR, "models.json"),
			JSON.stringify({
				providers: {
					synthetic: {
						baseUrl: "https://api.synthetic.new/openai/v1",
						apiKey: "SYNTHETIC_API_KEY",
						api: "openai-completions",
						models: [{ id: "hf:cached/model" }],
					},
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
		expect(readModelsJson().providers.synthetic.models).toEqual([{ id: "hf:cached/model" }]);
	});
});
