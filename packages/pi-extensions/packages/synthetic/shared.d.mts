import type { ProviderModelConfig } from "@mariozechner/pi-coding-agent";

export const PROVIDER_NAME: "synthetic";
export const SYNTHETIC_API_BASE_URL: string;
export const SYNTHETIC_MODELS_ENDPOINT: string;
export const DEFAULT_CONTEXT_WINDOW: number;
export const DEFAULT_MAX_TOKENS: number;
export const SYNTHETIC_COMPAT: {
	readonly supportsDeveloperRole: false;
	readonly supportsUsageInStreaming: false;
	readonly supportsStore: false;
	readonly requiresToolResultName: true;
};

export function parsePrice(price?: string): number;
export function createPlaceholderModel(id: string): ProviderModelConfig;
export function normalizeLiveModels(payload: { data: unknown[] }): ProviderModelConfig[];
