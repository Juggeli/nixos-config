export const PROVIDER_NAME = "synthetic";
export const SYNTHETIC_API_BASE_URL = "https://api.synthetic.new/openai/v1";
export const SYNTHETIC_MODELS_ENDPOINT = `${SYNTHETIC_API_BASE_URL}/models`;
export const DEFAULT_CONTEXT_WINDOW = 128_000;
export const DEFAULT_MAX_TOKENS = 32_768;
export const SYNTHETIC_COMPAT = {
	supportsDeveloperRole: false,
	supportsUsageInStreaming: false,
	supportsStore: false,
	requiresToolResultName: true,
};

const PRICE_PER_TOKEN_THRESHOLD = 0.001;

export function parsePrice(price) {
	if (!price) return 0;
	const match = price.match(/[\d.]+/);
	if (!match) return 0;
	const value = Number.parseFloat(match[0]);
	return value < PRICE_PER_TOKEN_THRESHOLD ? value * 1_000_000 : value;
}

export function createPlaceholderModel(id) {
	return {
		id,
		name: id,
		reasoning: true,
		input: ["text"],
		cost: {
			input: 0,
			output: 0,
			cacheRead: 0,
			cacheWrite: 0,
		},
		contextWindow: DEFAULT_CONTEXT_WINDOW,
		maxTokens: DEFAULT_MAX_TOKENS,
		compat: SYNTHETIC_COMPAT,
	};
}

export function normalizeLiveModels(payload) {
	const entries = Array.isArray(payload?.data) ? payload.data : [];
	const models = [];

	for (const model of entries) {
		if (!model?.always_on) continue;
		if (model.supported_features && !model.supported_features.includes("tools")) continue;

		const input = ["text"];
		if (model.input_modalities?.includes("image")) {
			input.push("image");
		}

		models.push({
			id: model.id,
			name: model.name || model.hugging_face_id || model.id,
			reasoning: model.supported_features?.includes("reasoning") ?? false,
			input,
			cost: {
				input: parsePrice(model.pricing?.prompt),
				output: parsePrice(model.pricing?.completion),
				cacheRead: parsePrice(model.pricing?.input_cache_reads),
				cacheWrite: parsePrice(model.pricing?.input_cache_writes),
			},
			contextWindow: model.context_length || DEFAULT_CONTEXT_WINDOW,
			maxTokens: model.max_output_length || DEFAULT_MAX_TOKENS,
			compat: SYNTHETIC_COMPAT,
		});
	}

	return models;
}
