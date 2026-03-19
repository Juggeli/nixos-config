import fs from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { readJson } from "../shared/sync-utils.mjs";

const PROVIDER_SOURCES = [
	{
		name: "synthetic",
		packageName: "synthetic",
		syncFnName: "syncSyntheticModels",
	},
	{
		name: "ollama",
		packageName: "ollama",
		syncFnName: "syncOllamaModels",
	},
];

function getAgentDir() {
	return process.env.PI_AGENT_DIR ?? path.join(process.env.HOME ?? "", ".pi", "agent");
}

function getConfiguredProviders(agentDir) {
	const modelsPath = path.join(agentDir, "models.json");
	const config = readJson(modelsPath, { providers: {} });
	return new Set(Object.keys(config.providers ?? {}));
}

function parseArgs(argv) {
	const providerNames = [];
	let ifMissing = false;

	for (let index = 0; index < argv.length; index += 1) {
		const arg = argv[index];

		if (arg === "--if-missing") {
			ifMissing = true;
			continue;
		}

		if (arg === "--provider") {
			const providerName = argv[index + 1];
			if (!providerName) {
				throw new Error("Missing value for --provider");
			}
			providerNames.push(providerName);
			index += 1;
			continue;
		}

		if (arg === "--help" || arg === "-h") {
			return { help: true, ifMissing: false, providerNames: [] };
		}

		providerNames.push(arg);
	}

	return {
		help: false,
		ifMissing,
		providerNames,
	};
}

function printHelp() {
	console.log("Usage: pi-sync-models [--if-missing] [--provider <name> | <name> ...]");
	console.log("");
	console.log("Examples:");
	console.log("  pi-sync-models");
	console.log("  pi-sync-models --if-missing");
	console.log("  pi-sync-models synthetic");
	console.log("  pi-sync-models --provider synthetic");
}

async function loadProviderSyncer(agentDir, provider) {
	const installedModulePath = path.join(agentDir, "packages", provider.packageName, "sync-models.mjs");
	const localModuleUrl = new URL(`../${provider.packageName}/sync-models.mjs`, import.meta.url);
	const moduleUrl = fs.existsSync(installedModulePath) ? pathToFileURL(installedModulePath).href : localModuleUrl.href;
	const module = await import(moduleUrl);

	if (typeof module[provider.syncFnName] !== "function") {
		throw new Error(`Provider ${provider.name} does not export ${provider.syncFnName}`);
	}

	return {
		name: provider.name,
		sync: module[provider.syncFnName],
	};
}

async function getProvidersToSync({ agentDir, ifMissing, providerNames }) {
	const requested = providerNames.length > 0 ? new Set(providerNames) : undefined;
	const configuredProviders = ifMissing ? getConfiguredProviders(agentDir) : new Set();
	const selectedSources = PROVIDER_SOURCES.filter((provider) => {
		if (requested && !requested.has(provider.name)) {
			return false;
		}

		if (ifMissing && configuredProviders.has(provider.name)) {
			return false;
		}

		return true;
	});

	if (requested) {
		const known = new Set(PROVIDER_SOURCES.map((provider) => provider.name));
		const unknownProviders = [...requested].filter((providerName) => !known.has(providerName));
		if (unknownProviders.length > 0) {
			throw new Error(`Unknown provider sync target(s): ${unknownProviders.join(", ")}`);
		}
	}

	return Promise.all(selectedSources.map((provider) => loadProviderSyncer(agentDir, provider)));
}

export async function syncProviderModels({
	agentDir = getAgentDir(),
	fetchFn = globalThis.fetch,
	ifMissing = false,
	providerNames = [],
} = {}) {
	const providers = await getProvidersToSync({ agentDir, ifMissing, providerNames });
	let updated = false;

	for (const provider of providers) {
		const didUpdate = await provider.sync({ agentDir, fetchFn });
		updated = updated || didUpdate;
	}

	return {
		updated,
		syncedProviders: providers.map((provider) => provider.name),
	};
}

if (process.argv[1] && path.basename(process.argv[1]) === "sync-models.mjs") {
	const args = parseArgs(process.argv.slice(2));
	if (args.help) {
		printHelp();
		process.exit(0);
	}

	await syncProviderModels({
		ifMissing: args.ifMissing,
		providerNames: args.providerNames,
	});
}
