import assert from "node:assert/strict";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { readJevCredentials } from "../src/credentials.ts";

function gatewayCredentials(
	apiKey: string,
	textModel = "google/gemini-2.5-flash-lite",
) {
	return {
		provider: "gateway" as const,
		apiKey,
		gatewayApiKey: apiKey,
		textModel,
		typesafeApiKey: "",
		typesafeModel: "jev-latest",
	};
}

test("credential file handles JSON syntax, precedence, reloads and missing keys", () => {
	const directory = mkdtempSync(join(tmpdir(), "jev-credentials-"));
	const path = join(directory, "config.json");
	try {
		assert.throws(
			() => readJevCredentials({ path, env: {} }),
			/AI_GATEWAY_API_KEY/,
		);
		writeFileSync(
			path,
			JSON.stringify({
				gateway: { apiKey: "file-test-key", textModel: "provider/model" },
			}),
			{ mode: 0o600 },
		);
		assert.deepEqual(
			readJevCredentials({ path, env: {} }),
			gatewayCredentials("file-test-key", "provider/model"),
		);
		assert.deepEqual(
			readJevCredentials({
				path,
				env: {
					AI_GATEWAY_API_KEY: "env-test-key",
					JEV_TEXT_MODEL: "other/model",
				},
			}),
			gatewayCredentials("env-test-key", "other/model"),
		);
		assert.equal(
			readJevCredentials({ path, env: { AI_GATEWAY_API_KEY: "  " } }).apiKey,
			"file-test-key",
		);
		writeFileSync(
			path,
			JSON.stringify({ gateway: { apiKey: "changed-test-key" } }),
		);
		assert.equal(
			readJevCredentials({ path, env: {} }).apiKey,
			"changed-test-key",
		);
		writeFileSync(path, "{}");
		assert.throws(
			() => readJevCredentials({ path, env: {} }),
			/AI_GATEWAY_API_KEY/,
		);
		writeFileSync(path, "{invalid");
		assert.throws(() => readJevCredentials({ path, env: {} }), /JSON syntax/);
		assert.throws(
			() => readJevCredentials({ path: directory, env: {} }),
			/Cannot read/,
		);
	} finally {
		rmSync(directory, { recursive: true, force: true });
	}
});

test("typesafe provider keys, env overrides, omitted provider, and invalid provider", () => {
	const directory = mkdtempSync(join(tmpdir(), "jev-credentials-"));
	const path = join(directory, "config.json");
	try {
		writeFileSync(
			path,
			JSON.stringify({
				provider: "typesafe",
				typesafe: { apiKey: "file-typesafe-key", model: "jev-file" },
			}),
			{ mode: 0o600 },
		);
		assert.deepEqual(readJevCredentials({ path, env: {} }), {
			provider: "typesafe",
			apiKey: "",
			gatewayApiKey: "",
			textModel: "google/gemini-2.5-flash-lite",
			typesafeApiKey: "file-typesafe-key",
			typesafeModel: "jev-file",
		});
		assert.deepEqual(
			readJevCredentials({
				path,
				env: {
					TYPESAFE_API_KEY: "env-typesafe-key",
					TYPESAFE_MODEL: "jev-env",
				},
			}),
			{
				provider: "typesafe",
				apiKey: "",
				gatewayApiKey: "",
				textModel: "google/gemini-2.5-flash-lite",
				typesafeApiKey: "env-typesafe-key",
				typesafeModel: "jev-env",
			},
		);
		writeFileSync(
			path,
			JSON.stringify({
				provider: "typesafe",
				gateway: { apiKey: "file-gateway-key" },
			}),
		);
		assert.throws(
			() => readJevCredentials({ path, env: {} }),
			/TYPESAFE_API_KEY/,
		);
		writeFileSync(
			path,
			JSON.stringify({
				gateway: { apiKey: "file-test-key" },
				typesafe: { apiKey: "unused-typesafe-key" },
			}),
		);
		assert.equal(readJevCredentials({ path, env: {} }).provider, "gateway");
		assert.throws(
			() =>
				readJevCredentials({
					path,
					env: { JB_PROVIDER: "other" },
				}),
			/gateway" or "typesafe/,
		);
	} finally {
		rmSync(directory, { recursive: true, force: true });
	}
});
