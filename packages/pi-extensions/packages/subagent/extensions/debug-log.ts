import { appendFileSync, mkdirSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";

export const SUBAGENT_DEBUG_LOG = process.env.PI_SUBAGENT_DEBUG_LOG || join(tmpdir(), "pi-subagent-debug.ndjson");

function truncate(value: unknown, max = 20000): unknown {
	if (typeof value === "string") return value.length > max ? `${value.slice(0, max)}...<truncated>` : value;
	if (Array.isArray(value)) return value.map((item) => truncate(item, max));
	if (value && typeof value === "object") {
		const out: Record<string, unknown> = {};
		for (const [key, item] of Object.entries(value)) out[key] = truncate(item, max);
		return out;
	}
	return value;
}

export function logSubagentDebug(event: string, data: Record<string, unknown>): void {
	try {
		mkdirSync(dirname(SUBAGENT_DEBUG_LOG), { recursive: true });
		const payload = truncate(data) as Record<string, unknown>;
		appendFileSync(SUBAGENT_DEBUG_LOG, `${JSON.stringify({ ts: new Date().toISOString(), kind: event, ...payload })}\n`);
	} catch {
		// Debug logging must never affect agent execution.
	}
}
