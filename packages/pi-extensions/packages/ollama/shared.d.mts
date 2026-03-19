import type { ProviderModelConfig } from "@mariozechner/pi-coding-agent";

export const PROVIDER_NAME: "ollama";
export const OLLAMA_API_BASE_URL: string;
export const OLLAMA_TAGS_ENDPOINT: string;
export const OLLAMA_SHOW_ENDPOINT: string;
export const DEFAULT_CONTEXT_WINDOW: number;
export const DEFAULT_MAX_TOKENS: number;
export const OLLAMA_COMPAT: {
	readonly supportsDeveloperRole: false;
	readonly supportsUsageInStreaming: false;
	readonly supportsStore: false;
	readonly requiresToolResultName: false;
};

export function createPlaceholderModel(id: string): ProviderModelConfig;
export function formatModelName(name: string, parameterCount?: number): string;
