import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { getAgentDir, type ExtensionAPI } from "@earendil-works/pi-coding-agent";

const configPath = join(getAgentDir(), "model-shortcuts.json");

function loadShortcuts() {
	if (!existsSync(configPath)) return {};

	try {
		const value: unknown = JSON.parse(readFileSync(configPath, "utf8"));
		if (
			typeof value !== "object" ||
			value === null ||
			Array.isArray(value) ||
			!Object.values(value).every((model) => typeof model === "string")
		) {
			throw new Error("expected an object of shortcut: provider/model pairs");
		}
		return value as Record<string, string>;
	} catch (error) {
		console.error(`Model shortcuts: could not load ${configPath}: ${error}`);
		return {};
	}
}

function saveShortcuts(shortcuts: Record<string, string>) {
	writeFileSync(configPath, `${JSON.stringify(shortcuts, null, 2)}\n`);
}

export default function modelShortcuts(pi: ExtensionAPI) {
	pi.registerCommand("model-shortcuts", {
		description: "Configure model keyboard shortcuts",
		handler: async (_args, ctx) => {
			const shortcuts = loadShortcuts();
			const action = await ctx.ui.select("Model shortcuts", ["Add or replace", "Remove"]);
			if (!action) return;

			if (action === "Remove") {
				const configured = Object.keys(shortcuts).sort();
				if (configured.length === 0) {
					ctx.ui.notify("No model shortcuts configured", "info");
					return;
				}

				const shortcut = await ctx.ui.select("Remove shortcut", configured);
				if (!shortcut) return;
				delete shortcuts[shortcut];
				saveShortcuts(shortcuts);
				ctx.ui.notify(`Removed ${shortcut}; reloading shortcuts`, "info");
				await ctx.reload();
				return;
			}

			const shortcut = await ctx.ui.input("Shortcut", "ctrl+4");
			if (!shortcut?.trim()) return;

			const models = ctx.modelRegistry
				.getAvailable()
				.map((model) => `${model.provider}/${model.id}`)
				.sort();
			const target = await ctx.ui.select("Select model", models);
			if (!target) return;

			shortcuts[shortcut.trim()] = target;
			saveShortcuts(shortcuts);
			ctx.ui.notify(`Saved ${shortcut.trim()} → ${target}; reloading shortcuts`, "info");
			await ctx.reload();
		},
	});

	for (const [shortcut, target] of Object.entries(loadShortcuts())) {
		const [provider, ...modelParts] = target.split("/");
		const modelId = modelParts.join("/");

		if (!provider || !modelId) {
			console.error(`Model shortcuts: ${shortcut} must target provider/model, got ${target}`);
			continue;
		}

		pi.registerShortcut(shortcut, {
			description: `Switch to ${target}`,
			handler: async (ctx) => {
				const model = ctx.modelRegistry.find(provider, modelId);
				if (!model) {
					ctx.ui.notify(`Model not found: ${target}`, "error");
					return;
				}

				if (await pi.setModel(model)) {
					ctx.ui.notify(`Model: ${target}`, "info");
				} else {
					ctx.ui.notify(`No credentials for ${target}`, "error");
				}
			},
		});
	}
}
