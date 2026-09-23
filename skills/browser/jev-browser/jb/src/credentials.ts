import { CONFIG_PATH, readConfigFile } from "./config.ts";

export type JevProvider = "gateway" | "typesafe";

export interface JevCredentials {
	provider: JevProvider;
	apiKey: string;
	gatewayApiKey: string;
	textModel: string;
	typesafeApiKey: string;
	typesafeModel: string;
}

const PROVIDERS: readonly JevProvider[] = ["gateway", "typesafe"];

function isJevProvider(value: string): value is JevProvider {
	return (PROVIDERS as readonly string[]).includes(value);
}

// Read per run without mutating process.env or exposing credentials to Chromium.
export function readJevCredentials(
	options: { path?: string; env?: NodeJS.ProcessEnv } = {},
): JevCredentials {
	const path = options.path ?? CONFIG_PATH;
	const env = options.env ?? process.env;
	const raw = readConfigFile(path);
	const gateway = raw.gateway as
		| { apiKey?: unknown; textModel?: unknown }
		| undefined;
	const typesafe = raw.typesafe as
		| { apiKey?: unknown; model?: unknown }
		| undefined;
	const value = (input: unknown) =>
		typeof input === "string" ? input.trim() : "";
	const providerValue =
		value(env.JB_PROVIDER) || value(raw.provider) || "gateway";
	if (!isJevProvider(providerValue)) {
		throw new Error(
			`jb provider must be "gateway" or "typesafe" (got ${JSON.stringify(providerValue)}).`,
		);
	}
	const gatewayApiKey = value(env.AI_GATEWAY_API_KEY) || value(gateway?.apiKey);
	const typesafeApiKey = value(env.TYPESAFE_API_KEY) || value(typesafe?.apiKey);
	const textModel =
		value(env.JEV_TEXT_MODEL) ||
		value(gateway?.textModel) ||
		"google/gemini-2.5-flash-lite";
	const typesafeModel =
		value(env.TYPESAFE_MODEL) || value(typesafe?.model) || "jev-latest";
	if (providerValue === "gateway" && !gatewayApiKey)
		throw new Error(
			`jb run requires AI_GATEWAY_API_KEY in the process environment or gateway.apiKey in ${path}.`,
		);
	if (providerValue === "typesafe" && !typesafeApiKey)
		throw new Error(
			`jb run requires TYPESAFE_API_KEY in the process environment or typesafe.apiKey in ${path}.`,
		);
	return {
		provider: providerValue,
		apiKey: gatewayApiKey,
		gatewayApiKey,
		textModel,
		typesafeApiKey,
		typesafeModel,
	};
}
