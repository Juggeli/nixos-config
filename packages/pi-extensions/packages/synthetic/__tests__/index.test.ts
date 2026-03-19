import * as fs from "node:fs";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { beforeEach, describe, expect, it, type Mock, vi } from "vitest";
import syntheticExtension, { updateQuotaStatus } from "../extensions/index.js";
import {
	type FetchFn,
	formatBucket,
	formatTimeDiff,
	getColorForPercent,
	parsePrice,
	type QuotaBucket,
	type QuotaResponse,
} from "../extensions/types.js";

function createMockContext(
	overrides: {
		provider?: string;
		apiKey?: string | null;
		branch?: Array<Record<string, unknown>>;
		foundModel?: { provider: string; id: string } | undefined;
	} = {},
): ExtensionContext {
	const provider = overrides.provider ?? "synthetic";
	const apiKey = overrides.apiKey !== undefined ? overrides.apiKey : "test-key";

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
			getApiKeyForProvider: vi.fn().mockResolvedValue(apiKey),
			registerProvider: vi.fn(),
		},
	} as unknown as ExtensionContext;
}

function createMockFetch(response: { ok: boolean; data?: unknown }): FetchFn {
	return vi.fn().mockResolvedValue({
		ok: response.ok,
		json: () => Promise.resolve(response.data),
	}) as unknown as FetchFn;
}

function createBucket(requests: number, limit: number, renewsInMs: number): QuotaBucket {
	return {
		requests,
		limit,
		renewsAt: new Date(Date.now() + renewsInMs).toISOString(),
	};
}

function createQuotaData(subscription: QuotaBucket, freeToolCalls: QuotaBucket) {
	return { subscription, freeToolCalls };
}

function createSyntheticModel(id = "hf:test/model") {
	return {
		id,
		name: "Test Model",
		reasoning: true,
		input: ["text"] as ("text" | "image")[],
		cost: { input: 0.55, output: 2.19, cacheRead: 0, cacheWrite: 0 },
		contextWindow: 128000,
		maxTokens: 32768,
		compat: {
			supportsDeveloperRole: false,
			supportsUsageInStreaming: false,
			supportsStore: false,
			requiresToolResultName: true,
		},
	};
}

describe("getColorForPercent", () => {
	it("returns success for low usage", () => {
		expect(getColorForPercent(0)).toBe("success");
		expect(getColorForPercent(50)).toBe("success");
		expect(getColorForPercent(69)).toBe("success");
	});

	it("returns warning for moderate usage", () => {
		expect(getColorForPercent(70)).toBe("warning");
		expect(getColorForPercent(85)).toBe("warning");
		expect(getColorForPercent(89)).toBe("warning");
	});

	it("returns error for high usage", () => {
		expect(getColorForPercent(90)).toBe("error");
		expect(getColorForPercent(95)).toBe("error");
		expect(getColorForPercent(100)).toBe("error");
	});
});

describe("formatTimeDiff", () => {
	it("formats days", () => {
		const now = new Date("2026-01-01T00:00:00Z");
		const future = new Date("2026-01-03T12:00:00Z");
		expect(formatTimeDiff(future, now)).toBe("2d");
	});

	it("formats hours", () => {
		const now = new Date("2026-01-01T00:00:00Z");
		const future = new Date("2026-01-01T05:30:00Z");
		expect(formatTimeDiff(future, now)).toBe("5h");
	});

	it("formats minutes", () => {
		const now = new Date("2026-01-01T00:00:00Z");
		const future = new Date("2026-01-01T00:45:00Z");
		expect(formatTimeDiff(future, now)).toBe("45m");
	});
});

describe("parsePrice", () => {
	it("returns 0 for undefined or empty", () => {
		expect(parsePrice(undefined)).toBe(0);
		expect(parsePrice("")).toBe(0);
	});

	it("converts per-token pricing to per-million", () => {
		expect(parsePrice("$0.00000055")).toBeCloseTo(0.55);
	});

	it("keeps per-million pricing as-is", () => {
		expect(parsePrice("$1.20")).toBeCloseTo(1.2);
		expect(parsePrice("$0.55")).toBeCloseTo(0.55);
	});
});

describe("formatBucket", () => {
	it("calculates percent and color correctly", () => {
		const now = new Date("2026-01-01T00:00:00Z");
		const bucket: QuotaBucket = { requests: 180, limit: 200, renewsAt: "2026-01-01T02:00:00Z" };
		const result = formatBucket("req", bucket, now);

		expect(result.label).toBe("req");
		expect(result.used).toBe(180);
		expect(result.limit).toBe(200);
		expect(result.percent).toBe(90);
		expect(result.color).toBe("error");
		expect(result.resetText).toBe("2h");
	});
});

describe("updateQuotaStatus", () => {
	beforeEach(() => {
		vi.restoreAllMocks();
	});

	it("clears status when provider is not synthetic", async () => {
		const ctx = createMockContext({ provider: "openai" });
		const fetchFn = createMockFetch({ ok: true });

		const result = await updateQuotaStatus(ctx, fetchFn, Date.now() - 1000);

		expect(ctx.ui.setStatus).toHaveBeenCalledWith("synthetic-quota", "");
		expect(fetchFn).not.toHaveBeenCalled();
		expect(result).toBe(0);
	});

	it("skips update when within rate limit interval", async () => {
		const ctx = createMockContext();
		const fetchFn = createMockFetch({ ok: true });
		const recentTimestamp = Date.now() - 1000;

		const result = await updateQuotaStatus(ctx, fetchFn, recentTimestamp);

		expect(fetchFn).not.toHaveBeenCalled();
		expect(result).toBe(recentTimestamp);
	});

	it("shows no key status when api key is missing", async () => {
		const ctx = createMockContext({ apiKey: null });
		const fetchFn = createMockFetch({ ok: true });

		await updateQuotaStatus(ctx, fetchFn, 0);

		expect(ctx.ui.setStatus).toHaveBeenCalledWith("synthetic-quota", "[dim]syn: no key[/dim]");
		expect(fetchFn).not.toHaveBeenCalled();
	});

	it("shows unavailable when API returns non-ok response", async () => {
		const ctx = createMockContext();
		const fetchFn = createMockFetch({ ok: false });

		await updateQuotaStatus(ctx, fetchFn, 0);

		expect(ctx.ui.setStatus).toHaveBeenCalledWith("synthetic-quota", "[dim]syn: unavailable[/dim]");
	});

	it("displays both subscription and tool call quotas", async () => {
		const ctx = createMockContext();
		const data = createQuotaData(createBucket(50, 200, 2 * 60 * 60 * 1000), createBucket(37, 750, 6 * 60 * 60 * 1000));
		const fetchFn = createMockFetch({ ok: true, data });

		const result = await updateQuotaStatus(ctx, fetchFn, 0);

		expect(ctx.ui.setStatus).toHaveBeenCalledWith("synthetic-quota", expect.stringContaining("req: 50/200"));
		expect(ctx.ui.setStatus).toHaveBeenCalledWith("synthetic-quota", expect.stringContaining("tools: 37/750"));
		expect(result).toBeGreaterThan(0);
	});

	it("sends correct authorization header", async () => {
		const ctx = createMockContext({ apiKey: "my-secret-key" });
		const data = createQuotaData(createBucket(0, 100, 60000), createBucket(0, 750, 60000));
		const fetchFn = createMockFetch({ ok: true, data });

		await updateQuotaStatus(ctx, fetchFn, 0);

		expect(fetchFn).toHaveBeenCalledWith("https://api.synthetic.new/v2/quotas", {
			headers: {
				Authorization: "Bearer my-secret-key",
				"Content-Type": "application/json",
			},
		});
	});

	it("shows error status on fetch failure", async () => {
		const ctx = createMockContext();
		const fetchFn = vi.fn().mockRejectedValue(new Error("network error")) as unknown as FetchFn;

		await updateQuotaStatus(ctx, fetchFn, 0);

		expect(ctx.ui.setStatus).toHaveBeenCalledWith("synthetic-quota", "[dim]syn: error[/dim]");
	});
});

describe("syntheticExtension", () => {
	beforeEach(() => {
		process.env.PI_AGENT_DIR = "/tmp/pi-test-home/.pi/agent";
		fs.rmSync("/tmp/pi-test-home", { recursive: true, force: true });
		fs.mkdirSync("/tmp/pi-test-home/.pi/agent", { recursive: true });
	});

	it("registers event handlers on the extension API", () => {
		const pi = {
			on: vi.fn(),
			appendEntry: vi.fn(),
			registerProvider: vi.fn(),
			setModel: vi.fn(),
		} as unknown as ExtensionAPI;
		const fetchFn = createMockFetch({ ok: true });

		syntheticExtension(pi, fetchFn);

		const registeredEvents = (pi.on as Mock).mock.calls.map((call) => call[0]);
		expect(registeredEvents).toContain("session_start");
		expect(registeredEvents).toContain("turn_end");
		expect(registeredEvents).toContain("model_select");
		expect(registeredEvents).toContain("agent_start");
		expect(registeredEvents).toContain("session_shutdown");
	});

	it("session_start fetches live models and re-registers provider", async () => {
		const pi = {
			on: vi.fn(),
			appendEntry: vi.fn(),
			registerProvider: vi.fn(),
			setModel: vi.fn(),
		} as unknown as ExtensionAPI;
		const liveModels = {
			data: [
				{
					id: "hf:test/model",
					hugging_face_id: "test/model",
					name: "Test Model",
					input_modalities: ["text"],
					output_modalities: ["text"],
					context_length: 128000,
					max_output_length: 32768,
					pricing: { prompt: "$0.55", completion: "$2.19" },
					supported_features: ["reasoning", "tools"],
					always_on: true,
				},
			],
		};
		const quotaData = createQuotaData(createBucket(0, 200, 60000), createBucket(0, 750, 60000));

		const fetchFn = vi.fn().mockImplementation((url: string) => {
			if (url.includes("/models")) {
				return Promise.resolve({ ok: true, json: () => Promise.resolve(liveModels) });
			}
			return Promise.resolve({ ok: true, json: () => Promise.resolve(quotaData) });
		}) as unknown as FetchFn;

		syntheticExtension(pi, fetchFn);

		const sessionStartHandler = (pi.on as Mock).mock.calls.find((call) => call[0] === "session_start")?.[1];
		const ctx = createMockContext();

		await sessionStartHandler(undefined, ctx);

		expect(pi.registerProvider).toHaveBeenCalledWith("synthetic", {
			baseUrl: "https://api.synthetic.new/openai/v1",
			apiKey: "SYNTHETIC_API_KEY",
			api: "openai-completions",
			models: expect.arrayContaining([expect.objectContaining({ id: "hf:test/model", reasoning: true })]),
		});
		expect(pi.appendEntry).toHaveBeenCalledWith(
			"synthetic-models",
			expect.arrayContaining([expect.objectContaining({ id: "hf:test/model" })]),
		);
	});

	it("session_start restores the previous synthetic model from cached models", async () => {
		const pi = {
			on: vi.fn(),
			appendEntry: vi.fn(),
			registerProvider: vi.fn(),
			setModel: vi.fn().mockResolvedValue(true),
		} as unknown as ExtensionAPI;
		const cachedModel = createSyntheticModel("hf:cached/model");
		const quotaData: QuotaResponse = createQuotaData(createBucket(0, 200, 60000), createBucket(0, 750, 60000));
		const fetchFn = vi.fn().mockImplementation((url: string) => {
			if (url.includes("/models")) {
				return Promise.resolve({ ok: false, status: 503, statusText: "Service Unavailable" });
			}
			return Promise.resolve({ ok: true, json: () => Promise.resolve(quotaData) });
		}) as unknown as FetchFn;

		syntheticExtension(pi, fetchFn);

		const sessionStartHandler = (pi.on as Mock).mock.calls.find((call) => call[0] === "session_start")?.[1];
		const ctx = createMockContext({
			provider: "openai",
			foundModel: { provider: "synthetic", id: "hf:cached/model" },
			branch: [
				{ type: "custom", customType: "synthetic-models", data: [cachedModel] },
				{ type: "model_change", provider: "synthetic", modelId: "hf:cached/model" },
			],
		});

		await sessionStartHandler(undefined, ctx);

		expect(pi.registerProvider).toHaveBeenCalledWith("synthetic", {
			baseUrl: "https://api.synthetic.new/openai/v1",
			apiKey: "SYNTHETIC_API_KEY",
			api: "openai-completions",
			models: [cachedModel],
		});
		expect(pi.setModel).toHaveBeenCalledWith({ provider: "synthetic", id: "hf:cached/model" });
	});

	it("session_start restores the synthetic default model from settings", async () => {
		const pi = {
			on: vi.fn(),
			appendEntry: vi.fn(),
			registerProvider: vi.fn(),
			setModel: vi.fn().mockResolvedValue(true),
		} as unknown as ExtensionAPI;
		const liveModels = {
			data: [
				{
					id: "hf:MiniMaxAI/MiniMax-M2.5",
					hugging_face_id: "MiniMaxAI/MiniMax-M2.5",
					name: "MiniMax M2.5",
					input_modalities: ["text"],
					output_modalities: ["text"],
					context_length: 128000,
					max_output_length: 32768,
					pricing: { prompt: "$0.55", completion: "$2.19" },
					supported_features: ["reasoning", "tools"],
					always_on: true,
				},
			],
		};
		const quotaData: QuotaResponse = createQuotaData(createBucket(0, 200, 60000), createBucket(0, 750, 60000));
		const fetchFn = vi.fn().mockImplementation((url: string) => {
			if (url.includes("/models")) {
				return Promise.resolve({ ok: true, json: () => Promise.resolve(liveModels) });
			}
			return Promise.resolve({ ok: true, json: () => Promise.resolve(quotaData) });
		}) as unknown as FetchFn;

		fs.writeFileSync(
			"/tmp/pi-test-home/.pi/agent/settings.json",
			JSON.stringify({
				defaultProvider: "synthetic",
				defaultModel: "hf:MiniMaxAI/MiniMax-M2.5",
			}),
		);

		syntheticExtension(pi, fetchFn);

		const sessionStartHandler = (pi.on as Mock).mock.calls.find((call) => call[0] === "session_start")?.[1];
		const ctx = createMockContext({
			provider: "openai",
			foundModel: { provider: "synthetic", id: "hf:MiniMaxAI/MiniMax-M2.5" },
		});

		await sessionStartHandler(undefined, ctx);

		expect(pi.setModel).toHaveBeenCalledWith({ provider: "synthetic", id: "hf:MiniMaxAI/MiniMax-M2.5" });
	});

	it("session_shutdown clears status", async () => {
		const pi = {
			on: vi.fn(),
			appendEntry: vi.fn(),
			registerProvider: vi.fn(),
			setModel: vi.fn(),
		} as unknown as ExtensionAPI;
		const fetchFn = createMockFetch({ ok: true });

		syntheticExtension(pi, fetchFn);

		const shutdownHandler = (pi.on as Mock).mock.calls.find((call) => call[0] === "session_shutdown")?.[1];
		const ctx = createMockContext();

		await shutdownHandler(undefined, ctx);

		expect(ctx.ui.setStatus).toHaveBeenCalledWith("synthetic-quota", "");
	});
});
