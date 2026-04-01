export interface LoopDetectorSettings {
	maxToolCalls: number;
	consecutiveThreshold: number;
	shortTextThreshold: number;
	longTextThreshold: number;
}

export interface ToolCallWindow {
	lastSignature?: string;
	totalCalls: number;
	consecutiveCount: number;
}

export interface ToolLoopDetectionResult {
	triggered: boolean;
	reason?: string;
	toolName?: string;
	repeatedCount?: number;
}

export interface TextDeltaWindow {
	lastChunk?: string;
	consecutiveCount: number;
}

export interface TextLoopDetectionResult {
	triggered: boolean;
	reason?: string;
	repeatedChunk?: string;
	repeatedCount?: number;
}

export const DEFAULT_LOOP_DETECTOR_SETTINGS: LoopDetectorSettings = {
	maxToolCalls: 48,
	consecutiveThreshold: 8,
	shortTextThreshold: 32,
	longTextThreshold: 12,
};

function sortObject(value: unknown): unknown {
	if (value === null || value === undefined) return value;
	if (typeof value !== "object") return value;
	if (Array.isArray(value)) return value.map(sortObject);

	const sorted: Record<string, unknown> = {};
	for (const key of Object.keys(value as Record<string, unknown>).sort()) {
		sorted[key] = sortObject((value as Record<string, unknown>)[key]);
	}
	return sorted;
}

export function createToolCallSignature(toolName: string, args?: Record<string, unknown> | null): string {
	if (!args || Object.keys(args).length === 0) return toolName;
	return `${toolName}::${JSON.stringify(sortObject(args))}`;
}

export function recordToolCall(
	window: ToolCallWindow | undefined,
	toolName: string,
	args: Record<string, unknown> | undefined,
	settings: LoopDetectorSettings = DEFAULT_LOOP_DETECTOR_SETTINGS,
): ToolCallWindow {
	const signature = createToolCallSignature(toolName, args);
	const lastSignature = window?.lastSignature;
	const consecutiveCount = lastSignature === signature ? (window?.consecutiveCount ?? 0) + 1 : 1;

	return {
		lastSignature: signature,
		totalCalls: (window?.totalCalls ?? 0) + 1,
		consecutiveCount: Math.min(consecutiveCount, settings.consecutiveThreshold + 1),
	};
}

export function detectToolLoop(
	window: ToolCallWindow | undefined,
	settings: LoopDetectorSettings = DEFAULT_LOOP_DETECTOR_SETTINGS,
): ToolLoopDetectionResult {
	if (!window) return { triggered: false };

	if (window.consecutiveCount >= settings.consecutiveThreshold && window.lastSignature) {
		return {
			triggered: true,
			toolName: window.lastSignature.split("::")[0],
			repeatedCount: window.consecutiveCount,
			reason: `Detected repetitive subagent loop: the same tool call repeated ${window.consecutiveCount} times.`,
		};
	}

	if (window.totalCalls > settings.maxToolCalls) {
		return {
			triggered: true,
			reason: `Detected runaway subagent loop: exceeded ${settings.maxToolCalls} tool calls without finishing.`,
		};
	}

	return { triggered: false };
}

function normalizeTextChunk(chunk: string): string {
	return chunk.replace(/\s+/g, " ").trim();
}

export function recordTextDelta(
	window: TextDeltaWindow | undefined,
	chunk: string,
): TextDeltaWindow | undefined {
	const normalized = normalizeTextChunk(chunk);
	if (!normalized) return window;

	if (window?.lastChunk === normalized) {
		return {
			lastChunk: normalized,
			consecutiveCount: window.consecutiveCount + 1,
		};
	}

	return {
		lastChunk: normalized,
		consecutiveCount: 1,
	};
}

export function detectTextLoop(
	window: TextDeltaWindow | undefined,
	settings: LoopDetectorSettings = DEFAULT_LOOP_DETECTOR_SETTINGS,
): TextLoopDetectionResult {
	if (!window?.lastChunk) return { triggered: false };

	const threshold = window.lastChunk.length === 1 ? settings.shortTextThreshold : settings.longTextThreshold;
	if (window.consecutiveCount < threshold) return { triggered: false };

	const preview = window.lastChunk.length > 24 ? `${window.lastChunk.slice(0, 24)}...` : window.lastChunk;
	return {
		triggered: true,
		repeatedChunk: window.lastChunk,
		repeatedCount: window.consecutiveCount,
		reason: `Detected repetitive subagent output loop: repeated "${preview}" ${window.consecutiveCount} times.`,
	};
}
