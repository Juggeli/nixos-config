import type { ProviderModelConfig } from "@mariozechner/pi-coding-agent";
import { normalizeLiveModels } from "../shared.mjs";
import { SYNTHETIC_MODELS_ENDPOINT } from "./config.js";
import type { FetchFn } from "./types.js";

export async function fetchSyntheticModels(
	apiKey: string | undefined,
	fetchFn: FetchFn,
): Promise<ProviderModelConfig[]> {
	try {
		const headers: Record<string, string> = { Accept: "application/json" };
		if (apiKey) {
			headers.Authorization = `Bearer ${apiKey}`;
		}

		const response = await fetchFn(SYNTHETIC_MODELS_ENDPOINT, { headers });
		if (!response.ok) {
			throw new Error(`Failed to fetch models: ${response.status} ${response.statusText}`);
		}

		return normalizeLiveModels(await response.json());
	} catch (error) {
		console.error("[synthetic] Failed to fetch models:", error);
		return [];
	}
}
