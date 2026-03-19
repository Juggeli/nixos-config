import type { ExtensionContext, ProviderModelConfig } from "@mariozechner/pi-coding-agent";

export function isProviderModelConfigArray(value: unknown): value is ProviderModelConfig[];
export function getCachedModels(ctx: ExtensionContext, cacheKey: string): ProviderModelConfig[];
export function getRestorableModelId(ctx: ExtensionContext, providerName: string): string | undefined;
export function getDefaultModelId(providerName: string): string | undefined;
export function haveSameModels(left: ProviderModelConfig[], right: ProviderModelConfig[]): boolean;
