import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const themeDir = join(dirname(fileURLToPath(import.meta.url)), "themes");
const themeName = "ui-customization";

export default function uiCustomization(pi: ExtensionAPI) {
	pi.on("resources_discover", async () => ({
		themePaths: [themeDir],
	}));

	pi.on("session_start", async (_event, ctx) => {
		if (ctx.mode !== "tui") return;
		const result = ctx.ui.setTheme(themeName);
		if (!result.success) {
			ctx.ui.notify(`ui-customization: ${result.error}`, "error");
		}
	});
}
