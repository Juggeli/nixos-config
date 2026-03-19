import fs from "node:fs";
import path from "node:path";
import { afterEach, describe, expect, it } from "vitest";
// @ts-expect-error
import { syncSyntheticModels } from "../sync-models.mjs";

const TEST_AGENT_DIR = "/tmp/pi-sync-models-test";

function readModelsJson() {
	return JSON.parse(fs.readFileSync(path.join(TEST_AGENT_DIR, "models.json"), "utf-8")) as {
		providers: Record<string, { models: Array<{ id: string; name: string }> }>;
	};
}

describe("syncSyntheticModels", () => {
	afterEach(() => {
		fs.rmSync(TEST_AGENT_DIR, { recursive: true, force: true });
	});

	it("writes live synthetic models and preserves other providers", async () => {
		fs.mkdirSync(TEST_AGENT_DIR, { recursive: true });
		fs.writeFileSync(
			path.join(TEST_AGENT_DIR, "models.json"),
			JSON.stringify({
				providers: {
					openrouter: {
						baseUrl: "https://openrouter.ai/api/v1",
						apiKey: "OPENROUTER_API_KEY",
						api: "openai-completions",
						models: [{ id: "openai/gpt-5.1-codex", name: "GPT-5.1 Codex" }],
					},
				},
			}),
		);

		await syncSyntheticModels({
			agentDir: TEST_AGENT_DIR,
			apiKey: "test-key",
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

		const config = readModelsJson();
		expect(config.providers.openrouter.models).toHaveLength(1);
		expect(config.providers.synthetic.models).toEqual(
			expect.arrayContaining([expect.objectContaining({ id: "hf:MiniMaxAI/MiniMax-M2.5", name: "MiniMax M2.5" })]),
		);
	});

	it("falls back to known synthetic models from settings and sessions when fetch fails", async () => {
		fs.mkdirSync(path.join(TEST_AGENT_DIR, "sessions", "cwd"), { recursive: true });
		fs.writeFileSync(
			path.join(TEST_AGENT_DIR, "settings.json"),
			JSON.stringify({
				defaultProvider: "synthetic",
				defaultModel: "hf:MiniMaxAI/MiniMax-M2.5",
			}),
		);
		fs.writeFileSync(
			path.join(TEST_AGENT_DIR, "sessions", "cwd", "session.jsonl"),
			[
				JSON.stringify({
					type: "model_change",
					provider: "synthetic",
					modelId: "hf:Qwen/Qwen3.5-397B-A17B",
				}),
				"",
			].join("\n"),
		);

		await syncSyntheticModels({
			agentDir: TEST_AGENT_DIR,
			apiKey: "test-key",
			fetchFn: async () =>
				({
					ok: false,
					status: 503,
					statusText: "Service Unavailable",
				}) as Response,
		});

		const syntheticModels = readModelsJson().providers.synthetic.models;
		expect(syntheticModels).toEqual(
			expect.arrayContaining([
				expect.objectContaining({ id: "hf:MiniMaxAI/MiniMax-M2.5" }),
				expect.objectContaining({ id: "hf:Qwen/Qwen3.5-397B-A17B" }),
			]),
		);
	});
});
