import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

export const PROVIDER_ID = "alibaba-token-plan";
export const BASE_URL = "https://token-plan.ap-southeast-1.maas.aliyuncs.com/compatible-mode/v1";

const ZERO_COST = { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 } as const;
const COMMON_COMPAT = {
	supportsStore: false,
	supportsDeveloperRole: false,
	supportsUsageInStreaming: true,
	maxTokensField: "max_tokens" as const,
	supportsStrictMode: false,
};

export const MODELS = [
	{
		id: "qwen3.8-max-preview",
		name: "Qwen3.8 Max Preview",
		reasoning: true,
		thinkingLevelMap: {
			off: null,
			minimal: null,
			low: "low",
			medium: null,
			high: "high",
			xhigh: "xhigh",
			max: null,
		},
		input: ["text", "image"] as const,
		cost: ZERO_COST,
		contextWindow: 983_616,
		maxTokens: 131_072,
		compat: { ...COMMON_COMPAT, supportsReasoningEffort: true },
	},
	{
		id: "deepseek-v4-pro",
		name: "DeepSeek V4 Pro",
		reasoning: true,
		thinkingLevelMap: { minimal: null, low: "low", medium: "medium", high: "high", xhigh: "xhigh", max: "max" },
		input: ["text"] as const,
		cost: ZERO_COST,
		contextWindow: 1_000_000,
		maxTokens: 393_216,
		compat: {
			...COMMON_COMPAT,
			supportsReasoningEffort: true,
			requiresReasoningContentOnAssistantMessages: true,
		},
	},
	{
		id: "glm-5.2",
		name: "GLM-5.2",
		reasoning: true,
		input: ["text"] as const,
		cost: ZERO_COST,
		contextWindow: 202_752,
		maxTokens: 65_536,
		compat: { ...COMMON_COMPAT, supportsReasoningEffort: true },
	},
];

const HYBRID_REASONING_MODELS = new Set(["deepseek-v4-pro", "glm-5.2"]);

function addThinkingToggle(payload: unknown, ctx: ExtensionContext): unknown {
	if (ctx.model?.provider !== PROVIDER_ID || !HYBRID_REASONING_MODELS.has(ctx.model.id)) return;
	if (typeof payload !== "object" || payload === null || Array.isArray(payload)) return;

	const request = payload as Record<string, unknown>;
	return {
		...request,
		enable_thinking: typeof request.reasoning_effort === "string",
	};
}

export default function alibabaTokenPlan(pi: ExtensionAPI) {
	pi.registerProvider(PROVIDER_ID, {
		name: "Alibaba Cloud Token Plan",
		baseUrl: BASE_URL,
		apiKey: "$ALIBABA_TOKEN_PLAN_API_KEY",
		api: "openai-completions",
		models: MODELS.map((model) => ({ ...model, input: [...model.input] })),
	});

	pi.on("before_provider_request", (event, ctx) => addThinkingToggle(event.payload, ctx));
}
