import * as fs from "node:fs";
import * as path from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { beforeEach, describe, expect, it, type Mock, vi } from "vitest";
import ollamaExtension from "../extensions/index.js";

const TEST_AGENT_DIR = "/tmp/pi-ollama-test/.pi/agent";

function createMockContext(
	overrides: {
		provider?: string;
		branch?: Array<Record<string, unknown>>;
		foundModel?: { provider: string; id: string } | undefined;
	} = {},
): ExtensionContext {
	const provider = overrides.provider ?? "ollama";

	return {
		model: provider ? { provider } : null,
		sessionManager: {
			getBranch: vi.fn().mockReturnValue(overrides.branch ?? []),
		},
		ui: {
			theme: {
				fg: (color: string, text: string) => `[${color}]${text}[/${color}]`,
			},
			setStatus: vi.fn(),
		},
		modelRegistry: {
			find: vi.fn().mockReturnValue(overrides.foundModel),
			registerProvider: vi.fn(),
		},
	} as unknown as ExtensionContext;
}

function createOllamaModel(id = "llama3.2:latest") {
	return {
		id,
		name: "llama3.2 (8B)",
		reasoning: false,
		input: ["text"] as ("text" | "image")[],
		cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
		contextWindow: 131072,
		maxTokens: 32768,
		compat: {
			supportsDeveloperRole: false,
			supportsUsageInStreaming: false,
			supportsStore: false,
			requiresToolResultName: false,
		},
	};
}

function writeModelsJson(models: Array<Record<string, unknown>>) {
	fs.writeFileSync(
		path.join(TEST_AGENT_DIR, "models.json"),
		JSON.stringify({
			providers: {
				ollama: {
					baseUrl: "https://ollama.com/v1",
					apiKey: "OLLAMA_API_KEY",
					api: "openai-completions",
					models,
				},
			},
		}),
	);
}

describe("ollamaExtension", () => {
	beforeEach(() => {
		process.env.PI_AGENT_DIR = TEST_AGENT_DIR;
		fs.rmSync("/tmp/pi-ollama-test", { recursive: true, force: true });
		fs.mkdirSync(TEST_AGENT_DIR, { recursive: true });
	});

	it("registers session_start event handler", () => {
		const pi = {
			on: vi.fn(),
			appendEntry: vi.fn(),
			registerProvider: vi.fn(),
			setModel: vi.fn(),
		} as unknown as ExtensionAPI;

		ollamaExtension(pi);

		const registeredEvents = (pi.on as Mock).mock.calls.map((call) => call[0]);
		expect(registeredEvents).toContain("session_start");
	});

	it("session_start reads enriched models from models.json and registers provider", async () => {
		const pi = {
			on: vi.fn(),
			appendEntry: vi.fn(),
			registerProvider: vi.fn(),
			setModel: vi.fn(),
		} as unknown as ExtensionAPI;

		const model = createOllamaModel("qwen3.5:397b");
		model.name = "qwen3.5:397b (397B)";
		model.reasoning = true;
		model.input = ["text", "image"];
		model.contextWindow = 262144;
		writeModelsJson([model]);

		ollamaExtension(pi);

		const sessionStartHandler = (pi.on as Mock).mock.calls.find((call) => call[0] === "session_start")?.[1];
		const ctx = createMockContext();

		await sessionStartHandler(undefined, ctx);

		expect(pi.registerProvider).toHaveBeenCalledWith("ollama", {
			baseUrl: "https://ollama.com/v1",
			apiKey: "OLLAMA_API_KEY",
			api: "openai-completions",
			models: expect.arrayContaining([
				expect.objectContaining({
					id: "qwen3.5:397b",
					reasoning: true,
					contextWindow: 262144,
					input: ["text", "image"],
				}),
			]),
		});
	});

	it("session_start restores the previous ollama model from cached models", async () => {
		const pi = {
			on: vi.fn(),
			appendEntry: vi.fn(),
			registerProvider: vi.fn(),
			setModel: vi.fn().mockResolvedValue(true),
		} as unknown as ExtensionAPI;
		const cachedModel = createOllamaModel("gemma3:27b");

		ollamaExtension(pi);

		const sessionStartHandler = (pi.on as Mock).mock.calls.find((call) => call[0] === "session_start")?.[1];
		const ctx = createMockContext({
			provider: "openai",
			foundModel: { provider: "ollama", id: "gemma3:27b" },
			branch: [
				{ type: "custom", customType: "ollama-models", data: [cachedModel] },
				{ type: "model_change", provider: "ollama", modelId: "gemma3:27b" },
			],
		});

		await sessionStartHandler(undefined, ctx);

		expect(pi.registerProvider).toHaveBeenCalledWith("ollama", {
			baseUrl: "https://ollama.com/v1",
			apiKey: "OLLAMA_API_KEY",
			api: "openai-completions",
			models: [cachedModel],
		});
		expect(pi.setModel).toHaveBeenCalledWith({ provider: "ollama", id: "gemma3:27b" });
	});

	it("session_start restores the ollama default model from settings", async () => {
		const pi = {
			on: vi.fn(),
			appendEntry: vi.fn(),
			registerProvider: vi.fn(),
			setModel: vi.fn().mockResolvedValue(true),
		} as unknown as ExtensionAPI;

		const model = createOllamaModel("deepseek-v3.2");
		writeModelsJson([model]);

		fs.writeFileSync(
			path.join(TEST_AGENT_DIR, "settings.json"),
			JSON.stringify({
				defaultProvider: "ollama",
				defaultModel: "deepseek-v3.2",
			}),
		);

		ollamaExtension(pi);

		const sessionStartHandler = (pi.on as Mock).mock.calls.find((call) => call[0] === "session_start")?.[1];
		const ctx = createMockContext({
			provider: "openai",
			foundModel: { provider: "ollama", id: "deepseek-v3.2" },
		});

		await sessionStartHandler(undefined, ctx);

		expect(pi.setModel).toHaveBeenCalledWith({ provider: "ollama", id: "deepseek-v3.2" });
	});

	it("session_start creates placeholder when no enriched or cached models exist", async () => {
		const pi = {
			on: vi.fn(),
			appendEntry: vi.fn(),
			registerProvider: vi.fn(),
			setModel: vi.fn().mockResolvedValue(true),
		} as unknown as ExtensionAPI;

		fs.writeFileSync(
			path.join(TEST_AGENT_DIR, "settings.json"),
			JSON.stringify({
				defaultProvider: "ollama",
				defaultModel: "llama3.2:latest",
			}),
		);

		ollamaExtension(pi);

		const sessionStartHandler = (pi.on as Mock).mock.calls.find((call) => call[0] === "session_start")?.[1];
		const ctx = createMockContext({
			provider: "openai",
			foundModel: { provider: "ollama", id: "llama3.2:latest" },
		});

		await sessionStartHandler(undefined, ctx);

		expect(pi.registerProvider).toHaveBeenCalledWith("ollama", {
			baseUrl: "https://ollama.com/v1",
			apiKey: "OLLAMA_API_KEY",
			api: "openai-completions",
			models: [expect.objectContaining({ id: "llama3.2:latest", name: "llama3.2:latest" })],
		});
	});

	it("session_start caches enriched models to session branch", async () => {
		const pi = {
			on: vi.fn(),
			appendEntry: vi.fn(),
			registerProvider: vi.fn(),
			setModel: vi.fn(),
		} as unknown as ExtensionAPI;

		const model = createOllamaModel("deepseek-v3.2");
		writeModelsJson([model]);

		ollamaExtension(pi);

		const sessionStartHandler = (pi.on as Mock).mock.calls.find((call) => call[0] === "session_start")?.[1];
		const ctx = createMockContext();

		await sessionStartHandler(undefined, ctx);

		expect(pi.appendEntry).toHaveBeenCalledWith("ollama-models", [model]);
	});
});
