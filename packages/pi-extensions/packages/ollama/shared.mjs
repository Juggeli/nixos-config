export const PROVIDER_NAME = "ollama";
export const OLLAMA_API_BASE_URL = "https://ollama.com/v1";
export const OLLAMA_TAGS_ENDPOINT = "https://ollama.com/api/tags";
export const OLLAMA_SHOW_ENDPOINT = "https://ollama.com/api/show";
export const DEFAULT_CONTEXT_WINDOW = 128_000;
export const DEFAULT_MAX_TOKENS = 32_768;
export const OLLAMA_COMPAT = {
	supportsDeveloperRole: false,
	supportsUsageInStreaming: false,
	supportsStore: false,
	requiresToolResultName: false,
};

export function createPlaceholderModel(id) {
	return {
		id,
		name: id,
		reasoning: false,
		input: ["text"],
		cost: {
			input: 0,
			output: 0,
			cacheRead: 0,
			cacheWrite: 0,
		},
		contextWindow: DEFAULT_CONTEXT_WINDOW,
		maxTokens: DEFAULT_MAX_TOKENS,
		compat: OLLAMA_COMPAT,
	};
}

export function formatModelName(name, parameterCount) {
	if (!parameterCount || typeof parameterCount !== "number") {
		return name;
	}

	const billions = parameterCount / 1_000_000_000;
	const label = billions >= 1 ? `${Math.round(billions)}B` : `${Math.round(parameterCount / 1_000_000)}M`;
	return `${name} (${label})`;
}
