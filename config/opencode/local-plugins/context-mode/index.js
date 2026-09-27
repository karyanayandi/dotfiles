import { createRequire } from "node:module";
import { dirname, resolve } from "node:path";
import { Plugin } from "@opencode/plugin";

const require = createRequire(import.meta.url);
const server = resolve(dirname(require.resolve("context-mode")), "../../../start.mjs");

export default Plugin.define({
  id: "context-mode",
  async setup(ctx) {
    await ctx.mcp.transform((editor) => {
      editor.set("context-mode", {
        type: "local",
        command: ["node", server],
        timeout: { startup: 90000 },
      });
    });
  },
});
