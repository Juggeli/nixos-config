export interface SyncOllamaModelsOptions {
	agentDir?: string;
	apiKey?: string;
	fetchFn?: typeof globalThis.fetch;
}

export function syncOllamaModels(options?: SyncOllamaModelsOptions): Promise<boolean>;
