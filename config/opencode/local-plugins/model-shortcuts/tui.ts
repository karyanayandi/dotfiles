import { Plugin } from "@opencode/plugin/tui";
import {
  describeTarget,
  loadShortcuts,
  saveShortcuts,
  slotDigit,
  slots,
  type Shortcuts,
  type ShortcutTarget,
} from "./shared.ts";

export default Plugin.define({
  id: "model-shortcuts",
  setup(context) {
    const [state, updateState] = context.storage.memory("shortcuts", {
      initial: { version: 0, map: loadShortcuts() },
    });

    async function switchTo(target: ShortcutTarget, slot: string) {
      const model = {
        providerID: target.providerID,
        id: target.modelID,
        ...(target.variant ? { variant: target.variant } : {}),
      };
      const route = context.ui.router.current();
      if (route.type !== "session") {
        try {
          const created = await context.client.session.create({ model });
          context.ui.tabs.focus(created.id);
        } catch (error) {
          context.ui.toast.show({
            message: `Could not start session with ${describeTarget(target)}`,
            variant: "error",
          });
          console.error(`model-shortcuts: create failed: ${error}`);
        }
        return;
      }
      try {
        await context.client.session.switchModel({
          sessionID: route.sessionID,
          model,
        });
        context.ui.toast.show({ message: `${slot} → ${describeTarget(target)}`, variant: "success" });
      } catch (error) {
        context.ui.toast.show({
          message: `No such model or variant: ${describeTarget(target)}`,
          variant: "error",
        });
        console.error(`model-shortcuts: switch failed: ${error}`);
      }
    }

    async function configure() {      const current: Shortcuts = { ...state.map };
      const slot = await context.ui.dialog.select({
        title: "Model shortcut slot",
        options: slots.map((s) => ({
          title: `${slotDigit(s)} (${s})`,
          value: s,
          description: current[s] ? describeTarget(current[s]) : "unassigned",
        })),
      });
      if (!slot) return;

      const location = context.location ?? context.data.location.default();
      await context.data.location.model.sync(location);
      const models = (context.data.location.model.list(location) ?? [])
        .map((model) => ({
          title: model.id,
          value: `${model.providerID}/${model.id}`,
          description: model.providerID,
        }))
        .sort((a, b) => a.value.localeCompare(b.value));
      if (models.length === 0) {
        context.ui.toast.show({ message: "No models available", variant: "warning" });
        return;
      }
      const picked = await context.ui.dialog.select({
        title: `Model for ${slot}`,
        options: models,
      });
      if (!picked) return;

      const slash = picked.indexOf("/");
      const previous = current[slot];
      const target: ShortcutTarget = {
        providerID: picked.slice(0, slash),
        modelID: picked.slice(slash + 1),
        ...(previous &&
        `${previous.providerID}/${previous.modelID}` === picked &&
        previous.variant
          ? { variant: previous.variant }
          : {}),
      };
      updateState((draft) => {
        draft.map[slot] = target;
        draft.version += 1;
      });
      saveShortcuts({ ...state.map });
      context.ui.toast.show({
        message: `Saved ${slot} → ${describeTarget(target)} (server palette needs service restart)`,
        variant: "success",
      });
    }

    return context.ui.slot({
      append: "app",
      render: () => {
        // Layer must be created under a component; setup has no Keymap provider.
        // Re-read the file every render so a stale memory store can never blank the layer.
        const version = state.version;
        void version;
        const current = loadShortcuts();
        const entries = Object.entries(current).sort(([a], [b]) => a.localeCompare(b));
        context.keymap.layer(() => ({
          mode: "global",
          // F-keys need no modifiers: no kitty/CSI-u, tmux, or compositor fights.
          priority: 100,
          commands: [
            ...entries.map(([slot, target]) => ({
              id: `model-shortcuts.slot-${slotDigit(slot)}`,
              title: `Model ${slotDigit(slot)} (${slot}): ${describeTarget(target)}`,
              group: "Model shortcuts",
              bind: slot,
              palette: true as const,
              run: () => void switchTo(target, slot),
            })),
            {
              id: "model-shortcuts.configure",              title: "Model shortcuts: configure…",
              group: "Model shortcuts",
              palette: true as const,
              slash: { name: "model-shortcut" },
              run: () => void configure(),
            },
          ],
        }));
        return null;
      },
    });
  },
});
