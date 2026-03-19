export function readJson<T>(filePath: string, fallback: T): T;
export function walkJsonlFiles(rootDir: string): string[];
export function collectKnownModelIds(agentDir: string, providerName: string): Set<string>;
export function mergeModels<T extends { id: string }>(
	liveModels: T[],
	knownModelIds: Set<string>,
	createPlaceholderModel: (id: string) => T,
): T[];
