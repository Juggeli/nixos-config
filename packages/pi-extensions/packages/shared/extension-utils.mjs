import fs from "node:fs";
import path from "node:path";

export function isProviderModelConfigArray(value) {
	if (!Array.isArray(value)) {
		return false;
	}

	return value.every((model) => {
		if (!model || typeof model !== "object") {
			return false;
		}

		const cost = model.cost;
		const input = model.input;

		return (
			typeof model.id === "string" &&
			typeof model.name === "string" &&
			typeof model.reasoning === "boolean" &&
			Array.isArray(input) &&
			input.every((item) => item === "text" || item === "image") &&
			typeof model.contextWindow === "number" &&
			typeof model.maxTokens === "number" &&
			!!cost &&
			typeof cost === "object" &&
			typeof cost.input === "number" &&
			typeof cost.output === "number" &&
			typeof cost.cacheRead === "number" &&
			typeof cost.cacheWrite === "number"
		);
	});
}

export function getCachedModels(ctx, cacheKey) {
	const branch = ctx.sessionManager.getBranch();

	for (let index = branch.length - 1; index >= 0; index -= 1) {
		const entry = branch[index];
		if (entry.type !== "custom" || entry.customType !== cacheKey) {
			continue;
		}

		return isProviderModelConfigArray(entry.data) ? entry.data : [];
	}

	return [];
}

export function getRestorableModelId(ctx, providerName) {
	const branch = ctx.sessionManager.getBranch();

	for (let index = branch.length - 1; index >= 0; index -= 1) {
		const entry = branch[index];
		if (entry.type !== "model_change") {
			continue;
		}

		return entry.provider === providerName ? entry.modelId : undefined;
	}

	return undefined;
}

export function getDefaultModelId(providerName) {
	const agentDir = process.env.PI_AGENT_DIR ?? path.join(process.env.HOME ?? "", ".pi", "agent");
	const settingsPath = path.join(agentDir, "settings.json");

	try {
		if (!fs.existsSync(settingsPath)) {
			return undefined;
		}

		const settings = JSON.parse(fs.readFileSync(settingsPath, "utf-8"));

		if (settings.defaultProvider !== providerName || !settings.defaultModel) {
			return undefined;
		}

		return settings.defaultModel;
	} catch {
		return undefined;
	}
}

export function haveSameModels(left, right) {
	return JSON.stringify(left) === JSON.stringify(right);
}
