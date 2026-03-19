import type { ExtensionAPI, ExtensionContext, ProviderModelConfig } from "@mariozechner/pi-coding-agent";
import {
	getCachedModels,
	getDefaultModelId,
	getRestorableModelId,
	haveSameModels,
} from "../../shared/extension-utils.mjs";
import { createPlaceholderModel, PROVIDER_NAME, SYNTHETIC_API_BASE_URL } from "../shared.mjs";
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
		const cachedModels = getCachedModels(ctx, MODELS_CACHE_KEY);
		if (cachedModels.length > 0) {
			registerSyntheticProvider(pi.registerProvider.bind(pi), cachedModels);
		}

		const targetModelId = getRestorableModelId(ctx, PROVIDER_NAME) ?? getDefaultModelId(PROVIDER_NAME);
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
