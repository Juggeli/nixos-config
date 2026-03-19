import fs from "node:fs";
import path from "node:path";
import { afterEach, describe, expect, it } from "vitest";
// @ts-expect-error
import { syncOllamaModels } from "../sync-models.mjs";

const TEST_AGENT_DIR = "/tmp/pi-ollama-sync-test";

function readModelsJson() {
	return JSON.parse(fs.readFileSync(path.join(TEST_AGENT_DIR, "models.json"), "utf-8")) as {
		providers: Record<
			string,
			{ models: Array<{ id: string; name: string; reasoning?: boolean; contextWindow?: number; input?: string[] }> }
		>;
	};
}

function createCloudFetch(
	models: Array<{ name: string; model: string }>,
	showResponses: Record<string, { capabilities: string[]; model_info: Record<string, unknown> }>,
) {
	return async (url: string, options?: RequestInit) => {
		if (url.includes("/api/tags")) {
			return { ok: true, json: async () => ({ models }) } as Response;
		}
		if (url.includes("/api/show")) {
			const body = JSON.parse((options?.body as string) ?? "{}") as { model: string };
			const details = showResponses[body.model];
			if (details) {
				return { ok: true, json: async () => details } as Response;
			}
			return { ok: false } as Response;
		}
		return { ok: false } as Response;
	};
}

describe("syncOllamaModels", () => {
	afterEach(() => {
		fs.rmSync(TEST_AGENT_DIR, { recursive: true, force: true });
	});

	it("writes ollama models and preserves other providers", async () => {
		fs.mkdirSync(TEST_AGENT_DIR, { recursive: true });
		fs.writeFileSync(
			path.join(TEST_AGENT_DIR, "models.json"),
			JSON.stringify({
				providers: {
					synthetic: {
						baseUrl: "https://api.synthetic.new/openai/v1",
						apiKey: "SYNTHETIC_API_KEY",
						api: "openai-completions",
						models: [{ id: "hf:test/model", name: "Test Model" }],
					},
				},
			}),
		);

		await syncOllamaModels({
			agentDir: TEST_AGENT_DIR,
			apiKey: "test-key",
			fetchFn: createCloudFetch([{ name: "gemma3", model: "gemma3:27b" }], {
				gemma3: {
					capabilities: ["completion", "vision"],
					model_info: { "gemma3.context_length": 131072, "general.parameter_count": 27000000000 },
				},
			}),
		});

		const config = readModelsJson();
		expect(config.providers.synthetic.models).toHaveLength(1);
		expect(config.providers.ollama.models).toEqual(
			expect.arrayContaining([
				expect.objectContaining({
					id: "gemma3:27b",
					name: "gemma3 (27B)",
					contextWindow: 131072,
					reasoning: false,
					input: ["text", "image"],
				}),
			]),
		);
	});

	it("detects thinking capability and sets reasoning to true", async () => {
		fs.mkdirSync(TEST_AGENT_DIR, { recursive: true });

		await syncOllamaModels({
			agentDir: TEST_AGENT_DIR,
			apiKey: "test-key",
			fetchFn: createCloudFetch([{ name: "qwen3.5", model: "qwen3.5:397b" }], {
				"qwen3.5": {
					capabilities: ["completion", "thinking", "tools", "vision"],
					model_info: {
						"qwen3.5.context_length": 262144,
						"general.parameter_count": 397000000000,
					},
				},
			}),
		});

		const ollamaModels = readModelsJson().providers.ollama.models;
		expect(ollamaModels[0]).toEqual(
			expect.objectContaining({
				id: "qwen3.5:397b",
				name: "qwen3.5 (397B)",
				reasoning: true,
				contextWindow: 262144,
				input: ["text", "image"],
			}),
		);
	});

	it("uses default context window when /api/show fails", async () => {
		fs.mkdirSync(TEST_AGENT_DIR, { recursive: true });

		await syncOllamaModels({
			agentDir: TEST_AGENT_DIR,
			apiKey: "test-key",
			fetchFn: createCloudFetch([{ name: "llama3.2", model: "llama3.2:latest" }], {}),
		});

		const ollamaModels = readModelsJson().providers.ollama.models;
		expect(ollamaModels[0]).toEqual(
			expect.objectContaining({
				contextWindow: 128000,
				reasoning: false,
				name: "llama3.2",
			}),
		);
	});

	it("falls back to known models from settings and sessions when fetch fails", async () => {
		fs.mkdirSync(path.join(TEST_AGENT_DIR, "sessions", "cwd"), { recursive: true });
		fs.writeFileSync(
			path.join(TEST_AGENT_DIR, "settings.json"),
			JSON.stringify({
				defaultProvider: "ollama",
				defaultModel: "llama3.2:latest",
			}),
		);
		fs.writeFileSync(
			path.join(TEST_AGENT_DIR, "sessions", "cwd", "session.jsonl"),
			[
				JSON.stringify({
					type: "model_change",
					provider: "ollama",
					modelId: "gemma3:27b",
				}),
				"",
			].join("\n"),
		);

		await syncOllamaModels({
			agentDir: TEST_AGENT_DIR,
			apiKey: "test-key",
			fetchFn: async () =>
				({
					ok: false,
					status: 503,
					statusText: "Service Unavailable",
				}) as Response,
		});

		const ollamaModels = readModelsJson().providers.ollama.models;
		expect(ollamaModels).toEqual(
			expect.arrayContaining([
				expect.objectContaining({ id: "llama3.2:latest" }),
				expect.objectContaining({ id: "gemma3:27b" }),
			]),
		);
	});
});
