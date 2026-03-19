import fs from "node:fs";
import path from "node:path";
import { collectKnownModelIds, mergeModels, readJson } from "../shared/sync-utils.mjs";
import {
	PROVIDER_NAME,
	SYNTHETIC_API_BASE_URL,
	SYNTHETIC_MODELS_ENDPOINT,
	createPlaceholderModel,
	normalizeLiveModels,
} from "./shared.mjs";

async function fetchLiveModels(apiKey, fetchFn) {
	const headers = { Accept: "application/json" };
	if (apiKey) {
		headers.Authorization = `Bearer ${apiKey}`;
	}

	const response = await fetchFn(SYNTHETIC_MODELS_ENDPOINT, { headers });
	if (!response.ok) {
		throw new Error(`Synthetic models request failed: ${response.status} ${response.statusText}`);
	}

	return normalizeLiveModels(await response.json());
}

export async function syncSyntheticModels({
	agentDir = process.env.PI_AGENT_DIR ?? path.join(process.env.HOME ?? "", ".pi", "agent"),
	apiKey = process.env.SYNTHETIC_API_KEY,
	fetchFn = globalThis.fetch,
} = {}) {
	fs.mkdirSync(agentDir, { recursive: true });

	const modelsPath = path.join(agentDir, "models.json");
	const existingConfig = readJson(modelsPath, { providers: {} });
	const knownModelIds = collectKnownModelIds(agentDir, PROVIDER_NAME);

	let liveModels = [];
	try {
		liveModels = await fetchLiveModels(apiKey, fetchFn);
	} catch {}

	const models = mergeModels(liveModels, knownModelIds, createPlaceholderModel);
	if (models.length === 0) {
		return false;
	}

	const nextConfig = {
		...existingConfig,
		providers: {
			...(existingConfig.providers ?? {}),
			[PROVIDER_NAME]: {
				baseUrl: SYNTHETIC_API_BASE_URL,
				apiKey: "SYNTHETIC_API_KEY",
				api: "openai-completions",
				models,
			},
		},
	};

	fs.writeFileSync(modelsPath, `${JSON.stringify(nextConfig, null, 2)}\n`, "utf-8");
	return true;
}

if (process.argv[1] && path.basename(process.argv[1]) === "sync-models.mjs") {
	await syncSyntheticModels();
}
