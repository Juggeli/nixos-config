import type { ExtensionContext } from "@mariozechner/pi-coding-agent";

export async function getSyntheticApiKey(ctx: ExtensionContext): Promise<string | undefined> {
	const envKey = process.env.SYNTHETIC_API_KEY;

	try {
		const authKey = await ctx.modelRegistry.getApiKeyForProvider("synthetic");
		if (authKey) return authKey;
	} catch {
		// Provider not registered yet
	}

	return envKey;
}
