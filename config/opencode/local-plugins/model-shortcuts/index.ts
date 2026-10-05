import { Plugin } from "@opencode/plugin";
import { describeTarget, loadShortcuts, slotDigit } from "./shared.ts";

export default Plugin.define({
  id: "model-shortcuts",
  async setup(ctx) {
    const shortcuts = loadShortcuts();
    if (Object.keys(shortcuts).length === 0) return;
    await ctx.command.transform((editor) => {
      for (const [slot, target] of Object.entries(shortcuts).sort(([a], [b]) => a.localeCompare(b))) {
        editor.add({
          name: `model-${slotDigit(slot)}`,
          description: `Switch to ${describeTarget(target)}`,
          execute: async ({ sessionID }) => {
            try {
              await ctx.session.switchModel({
                sessionID,
                model: {
                  providerID: target.providerID,
                  id: target.modelID,
                  ...(target.variant ? { variant: target.variant } : {}),
                },
              });
            } catch (error) {
              await ctx.session.synthetic({
                sessionID,
                text: `model-shortcuts: could not switch to ${describeTarget(target)}: ${error}`,
              });
            }
          },
        });
      }
    });
  },
});
