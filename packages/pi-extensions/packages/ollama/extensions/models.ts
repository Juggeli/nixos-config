import * as fs from "node:fs";
import * as path from "node:path";
import type { ProviderModelConfig } from "@mariozechner/pi-coding-agent";
import { PROVIDER_NAME } from "../shared.mjs";

function getAgentDir(): string {
	return process.env.PI_AGENT_DIR ?? path.join(process.env.HOME ?? "", ".pi", "agent");
}

export function readEnrichedModels(): ProviderModelConfig[] {
	const modelsPath = path.join(getAgentDir(), "models.json");

	try {
		if (!fs.existsSync(modelsPath)) {
			return [];
		}

		const config = JSON.parse(fs.readFileSync(modelsPath, "utf-8")) as {
			providers?: Record<string, { models?: ProviderModelConfig[] }>;
		};

		const models = config?.providers?.[PROVIDER_NAME]?.models;
		return Array.isArray(models) ? models : [];
	} catch {
		return [];
	}
}
