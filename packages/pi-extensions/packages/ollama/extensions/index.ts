import type { ExtensionAPI, ProviderModelConfig } from "@mariozechner/pi-coding-agent";
import {
	getCachedModels,
	getDefaultModelId,
	getRestorableModelId,
	haveSameModels,
} from "../../shared/extension-utils.mjs";
import { createPlaceholderModel, OLLAMA_API_BASE_URL, PROVIDER_NAME } from "../shared.mjs";
import { readEnrichedModels } from "./models.js";

const MODELS_CACHE_KEY = "ollama-models";

function registerOllamaProvider(
	registerProvider: ExtensionAPI["registerProvider"],
	models: ProviderModelConfig[],
): void {
	registerProvider(PROVIDER_NAME, {
		baseUrl: OLLAMA_API_BASE_URL,
		apiKey: "OLLAMA_API_KEY",
		api: "openai-completions",
		models,
	});
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", async (_event, ctx) => {
		const cachedModels = getCachedModels(ctx, MODELS_CACHE_KEY);
		if (cachedModels.length > 0) {
			registerOllamaProvider(pi.registerProvider.bind(pi), cachedModels);
		}

		const targetModelId = getRestorableModelId(ctx, PROVIDER_NAME) ?? getDefaultModelId(PROVIDER_NAME);
		const enrichedModels = readEnrichedModels();
		const models =
			enrichedModels.length > 0
				? enrichedModels
				: cachedModels.length > 0
					? cachedModels
					: targetModelId
						? [createPlaceholderModel(targetModelId)]
						: [];

		if (models.length > 0) {
			registerOllamaProvider(pi.registerProvider.bind(pi), models);
		}

		if (enrichedModels.length > 0 && !haveSameModels(cachedModels, enrichedModels)) {
			pi.appendEntry(MODELS_CACHE_KEY, enrichedModels);
		}

		if (targetModelId && ctx.model?.provider !== PROVIDER_NAME) {
			const model = ctx.modelRegistry.find(PROVIDER_NAME, targetModelId);
			if (model) {
				await pi.setModel(model);
			}
		}
	});
}
