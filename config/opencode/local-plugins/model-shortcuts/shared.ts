import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

export const configPath = join(homedir(), ".config", "opencode", "model-shortcuts.json");

export interface ShortcutTarget {
  providerID: string;
  modelID: string;
  variant?: string;
}

export type Shortcuts = Record<string, ShortcutTarget>;

export const slots = [
  "f1",
  "f2",
  "f3",
  "f4",
  "f5",
  "f6",
  "f7",
  "f8",
  "f9",
  "f10",
] as const;

export function slotDigit(slot: string): string {
  return String((((slots as readonly string[]).indexOf(slot) + 1) % 10));
}

function toTarget(value: unknown): ShortcutTarget | undefined {
  const raw = typeof value === "string" ? { model: value } : value;
  if (!raw || typeof raw !== "object") return undefined;
  const model = (raw as { model?: unknown }).model;
  if (typeof model !== "string") return undefined;
  const slash = model.indexOf("/");
  if (slash < 1 || slash === model.length - 1) return undefined;
  const variant = (raw as { variant?: unknown }).variant;
  return {
    providerID: model.slice(0, slash),
    modelID: model.slice(slash + 1),
    ...(typeof variant === "string" && variant ? { variant } : {}),
  };
}

export function parseShortcuts(value: unknown): Shortcuts {
  const out: Shortcuts = {};
  if (!value || typeof value !== "object") return out;
  for (const [slot, target] of Object.entries(value as Record<string, unknown>)) {
    if (!(slots as readonly string[]).includes(slot)) {
      console.error(`model-shortcuts: only f1 through f10 are supported; got ${slot}`);
      continue;
    }
    const parsed = toTarget(target);
    if (!parsed) {
      console.error(`model-shortcuts: ${slot} must target provider/model, got ${JSON.stringify(target)}`);
      continue;
    }
    out[slot] = parsed;
  }
  return out;
}

export function loadShortcuts(): Shortcuts {
  if (!existsSync(configPath)) return {};
  try {
    return parseShortcuts(JSON.parse(readFileSync(configPath, "utf8")));
  } catch (error) {
    console.error(`model-shortcuts: could not load ${configPath}: ${error}`);
    return {};
  }
}

export function saveShortcuts(shortcuts: Shortcuts): void {
  const raw: Record<string, string | { model: string; variant?: string }> = {};
  for (const [slot, target] of Object.entries(shortcuts)) {
    const model = `${target.providerID}/${target.modelID}`;
    raw[slot] = target.variant ? { model, variant: target.variant } : model;
  }
  writeFileSync(configPath, `${JSON.stringify(raw, null, 2)}\n`);
}

export function describeTarget(target: ShortcutTarget): string {
  return `${target.providerID}/${target.modelID}${target.variant ? ` · ${target.variant}` : ""}`;
}
