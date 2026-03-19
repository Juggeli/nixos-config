import fs from "node:fs";
import path from "node:path";

export function readJson(filePath, fallback) {
	try {
		if (!fs.existsSync(filePath)) {
			return fallback;
		}

		return JSON.parse(fs.readFileSync(filePath, "utf-8"));
	} catch {
		return fallback;
	}
}

export function walkJsonlFiles(rootDir) {
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

export function collectKnownModelIds(agentDir, providerName) {
	const modelIds = new Set();
	const settings = readJson(path.join(agentDir, "settings.json"), {});

	if (settings?.defaultProvider === providerName && typeof settings.defaultModel === "string") {
		modelIds.add(settings.defaultModel);
	}

	const modelsConfig = readJson(path.join(agentDir, "models.json"), { providers: {} });
	const existingModels = modelsConfig?.providers?.[providerName]?.models;
	if (Array.isArray(existingModels)) {
		for (const model of existingModels) {
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
				if (entry?.type === "model_change" && entry.provider === providerName && typeof entry.modelId === "string") {
					modelIds.add(entry.modelId);
				}
			}
		} catch {
			continue;
		}
	}

	return modelIds;
}

export function mergeModels(liveModels, knownModelIds, createPlaceholderModel) {
	const merged = [...liveModels];
	const seen = new Set(liveModels.map((model) => model.id));

	for (const modelId of knownModelIds) {
		if (seen.has(modelId)) continue;
		merged.push(createPlaceholderModel(modelId));
		seen.add(modelId);
	}

	return merged;
}
