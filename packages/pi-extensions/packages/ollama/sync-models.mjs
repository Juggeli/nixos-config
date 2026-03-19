import fs from "node:fs";
import path from "node:path";
import { collectKnownModelIds, mergeModels, readJson } from "../shared/sync-utils.mjs";
import {
	PROVIDER_NAME,
	OLLAMA_API_BASE_URL,
	OLLAMA_TAGS_ENDPOINT,
	OLLAMA_SHOW_ENDPOINT,
	OLLAMA_COMPAT,
	DEFAULT_CONTEXT_WINDOW,
	DEFAULT_MAX_TOKENS,
	createPlaceholderModel,
	formatModelName,
} from "./shared.mjs";

function extractContextLength(modelInfo) {
	if (!modelInfo || typeof modelInfo !== "object") {
		return undefined;
	}

	for (const key of Object.keys(modelInfo)) {
		if (key === "context_length" || key.endsWith(".context_length")) {
			const value = modelInfo[key];
			if (typeof value === "number" && value > 0) {
				return value;
			}
		}
	}

	return undefined;
}

async function fetchModelDetails(modelName, apiKey, fetchFn) {
	try {
		const headers = { "Content-Type": "application/json" };
		if (apiKey) {
			headers.Authorization = `Bearer ${apiKey}`;
		}

		const response = await fetchFn(OLLAMA_SHOW_ENDPOINT, {
			method: "POST",
			headers,
			body: JSON.stringify({ model: modelName }),
		});

		if (!response.ok) {
			return undefined;
		}

		return response.json();
	} catch {
		return undefined;
	}
}

function buildModelConfig(model, details) {
	const id = model.model || model.name;
	const capabilities = Array.isArray(details?.capabilities) ? details.capabilities : [];
	const contextLength = extractContextLength(details?.model_info);
	const parameterCount = details?.model_info?.["general.parameter_count"];

	const input = ["text"];
	if (capabilities.includes("vision")) {
		input.push("image");
	}

	return {
		id,
		name: formatModelName(model.name || id, parameterCount),
		reasoning: capabilities.includes("thinking"),
		input,
		cost: {
			input: 0,
			output: 0,
			cacheRead: 0,
			cacheWrite: 0,
		},
		contextWindow: contextLength || DEFAULT_CONTEXT_WINDOW,
		maxTokens: DEFAULT_MAX_TOKENS,
		compat: OLLAMA_COMPAT,
	};
}

async function fetchLiveModels(apiKey, fetchFn) {
	const headers = { Accept: "application/json" };
	if (apiKey) {
		headers.Authorization = `Bearer ${apiKey}`;
	}

	const response = await fetchFn(OLLAMA_TAGS_ENDPOINT, { headers });
	if (!response.ok) {
		throw new Error(`Ollama tags request failed: ${response.status} ${response.statusText}`);
	}

	const payload = await response.json();
	const entries = Array.isArray(payload?.models) ? payload.models : [];
	const validEntries = entries.filter((model) => model.model || model.name);

	const detailResults = await Promise.all(
		validEntries.map((model) => fetchModelDetails(model.name || model.model, apiKey, fetchFn)),
	);

	return validEntries.map((model, index) => buildModelConfig(model, detailResults[index]));
}

export async function syncOllamaModels({
	agentDir = process.env.PI_AGENT_DIR ?? path.join(process.env.HOME ?? "", ".pi", "agent"),
	apiKey = process.env.OLLAMA_API_KEY,
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
				baseUrl: OLLAMA_API_BASE_URL,
				apiKey: "OLLAMA_API_KEY",
				api: "openai-completions",
				models,
			},
		},
	};

	fs.writeFileSync(modelsPath, `${JSON.stringify(nextConfig, null, 2)}\n`, "utf-8");
	return true;
}

if (process.argv[1] && path.basename(process.argv[1]) === "sync-models.mjs") {
	await syncOllamaModels();
}
