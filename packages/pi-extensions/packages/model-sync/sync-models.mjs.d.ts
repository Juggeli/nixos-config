export interface SyncProviderModelsOptions {
	agentDir?: string;
	fetchFn?: typeof globalThis.fetch;
	ifMissing?: boolean;
	providerNames?: string[];
}

export interface SyncProviderModelsResult {
	updated: boolean;
	syncedProviders: string[];
}

export function syncProviderModels(options?: SyncProviderModelsOptions): Promise<SyncProviderModelsResult>;
