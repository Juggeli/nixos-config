"""
Patch for Letta to fix OpenAI API request compatibility with Synthetic API.

Synthetic API has stricter validation than OpenAI:
1. Requires 'stream' parameter to be explicitly set
2. Doesn't accept null tool_choice when tools is null
3. Doesn't accept null tools array

Also sets model-specific defaults:
- DeepSeek V3.2: top_p=0.95

This patch monkey-patches OpenAIClient methods to sanitize request payloads.
"""

MODEL_DEFAULTS = {
    "hf:deepseek-ai/DeepSeek-V3.2": {"top_p": 0.95},
}


def apply_patch():
    try:
        from letta.llm_api import openai_client

        original_build_request_data = openai_client.OpenAIClient.build_request_data
        original_request_async = openai_client.OpenAIClient.request_async

        def patched_build_request_data(self, *args, **kwargs):
            data = original_build_request_data(self, *args, **kwargs)
            if "input" not in data:
                if data.get("tools") is None:
                    data.pop("tools", None)
                    data.pop("tool_choice", None)
                if data.get("tool_choice") is None:
                    data.pop("tool_choice", None)
                model = data.get("model", "")
                if model in MODEL_DEFAULTS:
                    for key, value in MODEL_DEFAULTS[model].items():
                        if key not in data:
                            data[key] = value
            return data

        async def patched_request_async(self, request_data, llm_config):
            if "input" not in request_data and "stream" not in request_data:
                request_data["stream"] = False
            return await original_request_async(self, request_data, llm_config)

        openai_client.OpenAIClient.build_request_data = patched_build_request_data
        openai_client.OpenAIClient.request_async = patched_request_async
        print("[letta-stream-patch] Successfully patched OpenAIClient")
    except Exception as e:
        print(f"[letta-stream-patch] Failed to apply patch: {e}")

apply_patch()
