import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import {
	DynamicBorder,
	getAgentDir,
	type ExtensionAPI,
	type ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import {
	Container,
	decodeKittyPrintable,
	Key,
	matchesKey,
	type SelectItem,
	SelectList,
	Text,
} from "@earendil-works/pi-tui";

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

async function pick(ctx: ExtensionContext, title: string, items: SelectItem[]) {
	return ctx.ui.custom<string | null>((tui, theme, _keybindings, done) => {
		const container = new Container();
		let query = "";
		const queryText = new Text("", 1, 0);
		const listTheme = {
			selectedPrefix: (text: string) => theme.fg("accent", text),
			selectedText: (text: string) => theme.fg("accent", text),
			description: (text: string) => theme.fg("muted", text),
			scrollInfo: (text: string) => theme.fg("dim", text),
			noMatch: (text: string) => theme.fg("warning", text),
		};

		let list: SelectList;
		const updateList = () => {
			const terms = query.toLowerCase().split(/\s+/).filter(Boolean);
			const filtered = items.filter((item) => {
				const text = `${item.label} ${item.value} ${item.description ?? ""}`.toLowerCase();
				return terms.every((term) => text.includes(term));
			});
			list = new SelectList(filtered, Math.min(Math.max(filtered.length, 1), 12), listTheme);
			list.onSelect = (item) => done(item.value);
			list.onCancel = () => done(null);
			queryText.setText(theme.fg("muted", `Search: ${query || "_"}`));
		};
		updateList();

		container.addChild(new DynamicBorder((text: string) => theme.fg("accent", text)));
		container.addChild(new Text(theme.fg("accent", theme.bold(title)), 1, 0));
		container.addChild(queryText);
		const listComponent = {
			render: (width: number) => list.render(width),
			invalidate: () => list.invalidate(),
			handleInput(data: string) {
					const printable = decodeKittyPrintable(data) ?? (/^[^\x00-\x1f\x7f]+$/u.test(data) ? data : undefined);
				if (printable) {
					query += printable;
					updateList();
				} else if (matchesKey(data, Key.backspace)) {
					query = query.slice(0, -1);
					updateList();
				} else {
					list.handleInput(data);
				}
			},
		};
		container.addChild(listComponent);
		container.addChild(new Text(theme.fg("dim", "type to search • ↑↓ navigate • enter select • esc cancel"), 1, 0));
		container.addChild(new DynamicBorder((text: string) => theme.fg("accent", text)));

		return {
			render(width: number) {
				return container.render(width);
			},
			invalidate() {
				container.invalidate();
			},
			handleInput(data: string) {
				listComponent.handleInput(data);
				tui.requestRender();
			},
		};
	});
}

export default function modelShortcuts(pi: ExtensionAPI) {
	pi.registerCommand("model-shortcuts", {
		description: "Configure model keyboard shortcuts",
		handler: async (_args, ctx) => {
			const shortcuts = loadShortcuts();
			const action = await pick(ctx, "Model shortcuts", [
				{ value: "set", label: "Add or replace" },
				{ value: "remove", label: "Remove" },
			]);
			if (!action) return;

			if (action === "remove") {
				const items = Object.entries(shortcuts)
					.sort(([left], [right]) => left.localeCompare(right))
					.map(([shortcut, target]) => ({ value: shortcut, label: shortcut, description: target }));
				if (items.length === 0) {
					ctx.ui.notify("No model shortcuts configured", "info");
					return;
				}

				const shortcut = await pick(ctx, "Remove shortcut", items);
				if (!shortcut) return;
				delete shortcuts[shortcut];
				saveShortcuts(shortcuts);
				ctx.ui.notify(`Removed ${shortcut}; reloading shortcuts`, "info");
				await ctx.reload();
				return;
			}

			const defaults = Array.from({ length: 9 }, (_, index) => `ctrl+${index + 1}`);
			const items = [
				...Object.entries(shortcuts)
					.sort(([left], [right]) => left.localeCompare(right))
					.map(([shortcut, target]) => ({ value: shortcut, label: shortcut, description: target })),
				...defaults
					.filter((shortcut) => !(shortcut in shortcuts))
					.map((shortcut) => ({ value: shortcut, label: shortcut, description: "unassigned" })),
				{ value: "custom", label: "Custom shortcut…", description: "Type any Pi shortcut" },
			];
			const selected = await pick(ctx, "Select shortcut", items);
			if (!selected) return;
			const shortcut = selected === "custom" ? await ctx.ui.input("Shortcut", "ctrl+4") : selected;
			if (!shortcut?.trim()) return;

			const models = ctx.modelRegistry
				.getAvailable()
				.map((model) => ({ value: `${model.provider}/${model.id}`, label: model.id, description: model.provider }))
				.sort((left, right) => left.value.localeCompare(right.value));
			const target = await pick(ctx, "Select model", models);
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
