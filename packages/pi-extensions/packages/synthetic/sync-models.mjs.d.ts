export interface SyncSyntheticModelsOptions {
	agentDir?: string;
	apiKey?: string;
	fetchFn?: typeof globalThis.fetch;
}

export function syncSyntheticModels(options?: SyncSyntheticModelsOptions): Promise<boolean>;
