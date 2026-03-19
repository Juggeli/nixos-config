import fs from "node:fs";
import path from "node:path";
import {
	PROVIDER_NAME,
	SYNTHETIC_API_BASE_URL,
	SYNTHETIC_MODELS_ENDPOINT,
	createPlaceholderModel,
	normalizeLiveModels,
} from "./shared.mjs";

function readJson(filePath, fallback) {
	try {
		if (!fs.existsSync(filePath)) {
			return fallback;
		}

		return JSON.parse(fs.readFileSync(filePath, "utf-8"));
	} catch {
		return fallback;
	}
}

function walkJsonlFiles(rootDir) {
	if (!fs.existsSync(rootDir)) {
		return [];
	}

	const result = [];
	const stack = [rootDir];

	while (stack.length > 0) {
		const current = stack.pop();
		if (!current) continue;

		for (const entry of fs.readdirSync(current, { withFileTypes: true })) {
			const entryPath = path.join(current, entry.name);
			if (entry.isDirectory()) {
				stack.push(entryPath);
				continue;
			}
			if (entry.isFile() && entry.name.endsWith(".jsonl")) {
				result.push(entryPath);
			}
		}
	}

	return result;
}

function collectKnownModelIds(agentDir) {
	const modelIds = new Set();
	const settings = readJson(path.join(agentDir, "settings.json"), {});

	if (settings?.defaultProvider === PROVIDER_NAME && typeof settings.defaultModel === "string") {
		modelIds.add(settings.defaultModel);
	}

	const modelsConfig = readJson(path.join(agentDir, "models.json"), { providers: {} });
	const existingSyntheticModels = modelsConfig?.providers?.[PROVIDER_NAME]?.models;
	if (Array.isArray(existingSyntheticModels)) {
		for (const model of existingSyntheticModels) {
			if (typeof model?.id === "string") {
				modelIds.add(model.id);
			}
		}
	}

	for (const sessionFile of walkJsonlFiles(path.join(agentDir, "sessions"))) {
		try {
			const lines = fs.readFileSync(sessionFile, "utf-8").split("\n");
			for (const line of lines) {
				if (!line.trim()) continue;
				const entry = JSON.parse(line);
				if (entry?.type === "model_change" && entry.provider === PROVIDER_NAME && typeof entry.modelId === "string") {
					modelIds.add(entry.modelId);
				}
			}
		} catch {
			continue;
		}
	}

	return modelIds;
}

function mergeModels(liveModels, knownModelIds) {
	const merged = [...liveModels];
	const seen = new Set(liveModels.map((model) => model.id));

	for (const modelId of knownModelIds) {
		if (seen.has(modelId)) continue;
		merged.push(createPlaceholderModel(modelId));
		seen.add(modelId);
	}

	return merged;
}

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
	const knownModelIds = collectKnownModelIds(agentDir);

	let liveModels = [];
	try {
		liveModels = await fetchLiveModels(apiKey, fetchFn);
	} catch {}

	const models = mergeModels(liveModels, knownModelIds);
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
