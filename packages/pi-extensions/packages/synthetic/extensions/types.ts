import type { ThemeColor } from "@mariozechner/pi-coding-agent";

export { parsePrice } from "../shared.mjs";

export interface QuotaBucket {
	limit: number;
	requests: number;
	renewsAt: string;
}

export interface QuotaResponse {
	subscription: QuotaBucket;
	freeToolCalls: QuotaBucket;
}

export type FetchFn = typeof globalThis.fetch;

const USAGE_WARNING_PERCENT = 70;
const USAGE_ERROR_PERCENT = 90;

export function getColorForPercent(percent: number): ThemeColor {
	if (percent >= USAGE_ERROR_PERCENT) return "error";
	if (percent >= USAGE_WARNING_PERCENT) return "warning";
	return "success";
}

export function formatTimeDiff(renewsAt: Date, now: Date): string {
	const diffMs = renewsAt.getTime() - now.getTime();
	const diffMinutes = Math.floor(diffMs / (1000 * 60));
	const diffHours = Math.floor(diffMinutes / 60);
	const diffDays = Math.floor(diffHours / 24);

	if (diffDays > 0) return `${diffDays}d`;
	if (diffHours > 0) return `${diffHours}h`;
	return `${diffMinutes}m`;
}

export interface FormattedBucket {
	label: string;
	used: number;
	limit: number;
	percent: number;
	color: ThemeColor;
	resetText: string;
}

export function formatBucket(label: string, bucket: QuotaBucket, now: Date): FormattedBucket {
	const percent = Math.round((bucket.requests / bucket.limit) * 100);
	return {
		label,
		used: bucket.requests,
		limit: bucket.limit,
		percent,
		color: getColorForPercent(percent),
		resetText: formatTimeDiff(new Date(bucket.renewsAt), now),
	};
}
