import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { describe, expect, it, vi } from "vitest";
import alibabaTokenPlan, { BASE_URL, MODELS, PROVIDER_ID } from "../extensions/index.js";

describe("Alibaba Token Plan provider", () => {
	it("registers endpoint, API key, and supported models", () => {
		const registerProvider = vi.fn();
		const on = vi.fn();

		alibabaTokenPlan({ registerProvider, on } as unknown as ExtensionAPI);

		expect(registerProvider).toHaveBeenCalledOnce();
		expect(registerProvider).toHaveBeenCalledWith(
			PROVIDER_ID,
			expect.objectContaining({
				name: "Alibaba Cloud Token Plan",
				baseUrl: BASE_URL,
				apiKey: "$ALIBABA_TOKEN_PLAN_API_KEY",
				api: "openai-completions",
				models: [
					expect.objectContaining({ id: "qwen3.8-max-preview", input: ["text", "image"] }),
					expect.objectContaining({ id: "deepseek-v4-pro" }),
					expect.objectContaining({ id: "glm-5.2" }),
				],
			}),
		);
		expect(MODELS).toHaveLength(3);
	});

	it("adds enable_thinking for models using reasoning_effort", () => {
		const on = vi.fn();
		alibabaTokenPlan({ registerProvider: vi.fn(), on } as unknown as ExtensionAPI);
		const handler = on.mock.calls.find(([event]) => event === "before_provider_request")?.[1];

		expect(handler).toBeTypeOf("function");
		expect(
			handler(
				{ payload: { model: "deepseek-v4-pro", reasoning_effort: "high" } },
				{ model: { provider: PROVIDER_ID, id: "deepseek-v4-pro" } },
			),
		).toEqual({ model: "deepseek-v4-pro", reasoning_effort: "high", enable_thinking: true });
		expect(handler({ payload: { model: "glm-5.2" } }, { model: { provider: PROVIDER_ID, id: "glm-5.2" } })).toEqual({
			model: "glm-5.2",
			enable_thinking: false,
		});
	});
});
