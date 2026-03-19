import * as fs from "node:fs";
import * as path from "node:path";
import type { ExtensionAPI, ExtensionContext, ProviderModelConfig } from "@mariozechner/pi-coding-agent";
import { PROVIDER_NAME, SYNTHETIC_API_BASE_URL, createPlaceholderModel } from "../shared.mjs";
import { getSyntheticApiKey } from "./auth.js";
import { SYNTHETIC_QUOTAS_ENDPOINT } from "./config.js";
import { fetchSyntheticModels } from "./models.js";
import { type FetchFn, formatBucket, type QuotaResponse } from "./types.js";

const STATUS_KEY = "synthetic-quota";
const MODELS_CACHE_KEY = "synthetic-models";
const MIN_REFRESH_INTERVAL_MS = 30_000;

function registerSyntheticProvider(
	registerProvider: ExtensionAPI["registerProvider"],
	models: ProviderModelConfig[],
): void {
	registerProvider(PROVIDER_NAME, {
		baseUrl: SYNTHETIC_API_BASE_URL,
		apiKey: "SYNTHETIC_API_KEY",
		api: "openai-completions",
		models,
	});
}

function isProviderModelConfigArray(value: unknown): value is ProviderModelConfig[] {
	if (!Array.isArray(value)) {
		return false;
	}

	return value.every((model) => {
		if (!model || typeof model !== "object") {
			return false;
		}

		const candidate = model as Record<string, unknown>;
		const cost = candidate.cost;
		const input = candidate.input;

		return (
			typeof candidate.id === "string" &&
			typeof candidate.name === "string" &&
			typeof candidate.reasoning === "boolean" &&
			Array.isArray(input) &&
			input.every((item) => item === "text" || item === "image") &&
			typeof candidate.contextWindow === "number" &&
			typeof candidate.maxTokens === "number" &&
			!!cost &&
			typeof cost === "object" &&
			typeof (cost as Record<string, unknown>).input === "number" &&
			typeof (cost as Record<string, unknown>).output === "number" &&
			typeof (cost as Record<string, unknown>).cacheRead === "number" &&
			typeof (cost as Record<string, unknown>).cacheWrite === "number"
		);
	});
}

function getCachedSyntheticModels(ctx: ExtensionContext): ProviderModelConfig[] {
	const branch = ctx.sessionManager.getBranch();

	for (let index = branch.length - 1; index >= 0; index -= 1) {
		const entry = branch[index];
		if (entry.type !== "custom" || entry.customType !== MODELS_CACHE_KEY) {
			continue;
		}

		return isProviderModelConfigArray(entry.data) ? entry.data : [];
	}

	return [];
}

function getRestorableSyntheticModelId(ctx: ExtensionContext): string | undefined {
	const branch = ctx.sessionManager.getBranch();

	for (let index = branch.length - 1; index >= 0; index -= 1) {
		const entry = branch[index];
		if (entry.type !== "model_change") {
			continue;
		}

		return entry.provider === PROVIDER_NAME ? entry.modelId : undefined;
	}

	return undefined;
}

function getDefaultSyntheticModelId(): string | undefined {
	const agentDir = process.env.PI_AGENT_DIR ?? path.join(process.env.HOME ?? "", ".pi", "agent");
	const settingsPath = path.join(agentDir, "settings.json");

	try {
		if (!fs.existsSync(settingsPath)) {
			return undefined;
		}

		const settings = JSON.parse(fs.readFileSync(settingsPath, "utf-8")) as {
			defaultProvider?: string;
			defaultModel?: string;
		};

		if (settings.defaultProvider !== PROVIDER_NAME || !settings.defaultModel) {
			return undefined;
		}

		return settings.defaultModel;
	} catch {
		return undefined;
	}
}

function haveSameModels(left: ProviderModelConfig[], right: ProviderModelConfig[]): boolean {
	return JSON.stringify(left) === JSON.stringify(right);
}

export async function updateQuotaStatus(ctx: ExtensionContext, fetchFn: FetchFn, lastUpdate: number): Promise<number> {
	const theme = ctx.ui.theme;

	if (ctx.model?.provider !== PROVIDER_NAME) {
		ctx.ui.setStatus(STATUS_KEY, "");
		return 0;
	}

	if (Date.now() - lastUpdate < MIN_REFRESH_INTERVAL_MS) {
		return lastUpdate;
	}

	const apiKey = await getSyntheticApiKey(ctx);
	if (!apiKey) {
		ctx.ui.setStatus(STATUS_KEY, theme.fg("dim", "syn: no key"));
		return lastUpdate;
	}

	try {
		const response = await fetchFn(SYNTHETIC_QUOTAS_ENDPOINT, {
			headers: {
				Authorization: `Bearer ${apiKey}`,
				"Content-Type": "application/json",
			},
		});

		if (!response.ok) {
			ctx.ui.setStatus(STATUS_KEY, theme.fg("dim", "syn: unavailable"));
			return lastUpdate;
		}

		const data = (await response.json()) as QuotaResponse;
		const now = new Date();

		const buckets = [formatBucket("req", data.subscription, now), formatBucket("tools", data.freeToolCalls, now)];

		const parts = buckets.map(
			(b) => `${b.label}: ${b.used}/${b.limit} (${theme.fg(b.color, `${b.percent}%`)}) ${b.resetText}`,
		);

		ctx.ui.setStatus(STATUS_KEY, `syn ${parts.join(" · ")}`);
		return Date.now();
	} catch (err) {
		console.error("[synthetic] quota error:", err);
		ctx.ui.setStatus(STATUS_KEY, theme.fg("dim", "syn: error"));
		return lastUpdate;
	}
}

export default function (pi: ExtensionAPI, fetchFn: FetchFn = globalThis.fetch) {
	let lastUpdate = 0;

	pi.on("session_start", async (_event, ctx) => {
		const cachedModels = getCachedSyntheticModels(ctx);
		if (cachedModels.length > 0) {
			registerSyntheticProvider(pi.registerProvider.bind(pi), cachedModels);
		}

		const targetModelId = getRestorableSyntheticModelId(ctx) ?? getDefaultSyntheticModelId();
		const apiKey = await getSyntheticApiKey(ctx);
		const liveModels = await fetchSyntheticModels(apiKey, fetchFn);
		const models =
			liveModels.length > 0
				? liveModels
				: cachedModels.length > 0
					? cachedModels
					: targetModelId
						? [createPlaceholderModel(targetModelId)]
						: [];

		if (models.length > 0) {
			registerSyntheticProvider(pi.registerProvider.bind(pi), models);
		}

		if (liveModels.length > 0 && !haveSameModels(cachedModels, liveModels)) {
			pi.appendEntry(MODELS_CACHE_KEY, liveModels);
		}

		if (targetModelId && ctx.model?.provider !== PROVIDER_NAME) {
			const model = ctx.modelRegistry.find(PROVIDER_NAME, targetModelId);
			if (model) {
				await pi.setModel(model);
			}
		}

		lastUpdate = 0;
		lastUpdate = await updateQuotaStatus(ctx, fetchFn, lastUpdate);
	});

	pi.on("turn_end", async (_event, ctx) => {
		lastUpdate = await updateQuotaStatus(ctx, fetchFn, lastUpdate);
	});

	pi.on("model_select", async (_event, ctx) => {
		lastUpdate = await updateQuotaStatus(ctx, fetchFn, lastUpdate);
	});

	pi.on("agent_start", async (_event, ctx) => {
		if (ctx.model?.provider === PROVIDER_NAME) {
			lastUpdate = await updateQuotaStatus(ctx, fetchFn, lastUpdate);
		}
	});

	pi.on("session_shutdown", async (_event, ctx) => {
		ctx.ui.setStatus(STATUS_KEY, "");
		lastUpdate = 0;
	});
}
