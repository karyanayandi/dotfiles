import { describe, expect, test, vi } from "vitest"
import {
  getAgentDir,
  initTheme,
  type KeybindingsManager,
  type ExtensionAPI,
  type ExtensionCommandContext,
  type ExtensionContext,
  type ExtensionUIContext,
  type Theme,
} from "@earendil-works/pi-coding-agent"
import { type Component, type TUI, visibleWidth } from "@earendil-works/pi-tui"
import { join } from "node:path"
import type { SubagentReadModel } from "../subagents/src/manager.ts"
import type { SubagentSnapshot } from "../subagents/src/domain.ts"
import { openSubagentTakeover } from "../subagents/src/ui/takeover.ts"
import uiExtension from "./index.js"

const files = vi.hoisted(() => new Map<string, string>())
vi.mock("node:fs", async (loadOriginal) => {
  const original = await loadOriginal<typeof import("node:fs")>()
  return {
    ...original,
    existsSync: (path: Parameters<typeof original.existsSync>[0]) =>
      files.has(String(path)) || original.existsSync(path),
    readFileSync: (...args: Parameters<typeof original.readFileSync>) =>
      files.get(String(args[0])) ?? original.readFileSync(...args),
    writeFileSync: (
      path: Parameters<typeof original.writeFileSync>[0],
      data: string,
    ) => {
      if (!files.has(String(path))) throw new Error(`Unexpected write: ${path}`)
      files.set(String(path), data)
    },
  }
})

initTheme("dark")

const theme = {
  bg: (_color: string, text: string) => text,
  bold: (text: string) => text,
  fg: (_color: string, text: string) => text,
  italic: (text: string) => text,
} as unknown as Theme

const snapshot: SubagentSnapshot = {
  id: "sa-1",
  origin: "model",
  backend: "pi",
  title: "layout regression",
  prompt: "read file",
  cwd: "/tmp/ui-takeover-test",
  status: "done",
  createdAt: 0,
  meta: { backend: "pi" },
  usage: {},
  transcript: [
    { kind: "user", text: "Read demo.ts" },
    {
      kind: "assistant",
      parts: [
        { type: "thinking", text: "Checking file" },
        {
          type: "toolCall",
          toolId: "t1",
          name: "read",
          argsPreview: "demo.ts",
        },
      ],
    },
    {
      kind: "toolResult",
      toolId: "t1",
      name: "read",
      isError: false,
      outputPreview: "hello",
    },
  ],
  liveTools: [],
  queued: [],
  finalText: "",
  turns: 1,
}

describe("takeover UI layout integration", () => {
  test.each([
    {
      global: "minimal",
      project: undefined,
      trusted: false,
      expected: "minimal",
    },
    { global: "lite", project: undefined, trusted: false, expected: "lite" },
    { global: "full", project: undefined, trusted: false, expected: "full" },
    { global: "off", project: undefined, trusted: false, expected: "off" },
    { global: "full", project: "lite", trusted: true, expected: "lite" },
    { global: "lite", project: "full", trusted: true, expected: "full" },
    { global: "full", project: "minimal", trusted: false, expected: "full" },
  ])(
    "uses resolved setting $expected ($global/$project, trusted=$trusted)",
    async (settings) => {
      const globalPath = join(getAgentDir(), "settings.json")
      const projectPath = join(snapshot.cwd, ".pi/settings.json")
      files.set(globalPath, JSON.stringify({ ui: { layout: settings.global } }))
      files.set(
        projectPath,
        JSON.stringify({ ui: { layout: settings.project } }),
      )
      const handlers = new Map<
        string,
        (event: { reason: string }, ctx: ExtensionContext) => unknown
      >()
      let command: Parameters<ExtensionAPI["registerCommand"]>[1] | undefined
      const pi = {
        on: (
          name: string,
          handler: (
            event: { reason: string },
            ctx: ExtensionContext,
          ) => unknown,
        ) => handlers.set(name, handler),
        registerTool: vi.fn(),
        registerCommand: (
          _name: string,
          value: Parameters<ExtensionAPI["registerCommand"]>[1],
        ) => {
          command = value
        },
        exec: vi.fn().mockResolvedValue({ code: 0, stdout: "", killed: false }),
      } as unknown as ExtensionAPI
      let component: (Component & { dispose?: () => void }) | undefined
      const tui = {
        terminal: { rows: 30 },
        requestRender: vi.fn(),
      } as unknown as TUI
      const keybindings = {
        getKeys: () => ["key"],
        matches: () => false,
      } as unknown as KeybindingsManager
      const custom = async (
        factory: Parameters<ExtensionUIContext["custom"]>[0],
      ) => {
        component = await factory(tui, theme, keybindings, () => {})
        return undefined
      }
      const ui = {
        custom,
        theme,
        setFooter: vi.fn(),
        setWorkingVisible: vi.fn(),
        setHiddenThinkingLabel: vi.fn(),
        setEditorComponent: vi.fn(),
        notify: vi.fn(),
      } as unknown as ExtensionUIContext
      const ctx = {
        ui,
        cwd: snapshot.cwd,
        isProjectTrusted: () => settings.trusted,
      } as unknown as ExtensionCommandContext
      const view = {
        get: () => snapshot,
        subscribeTo: () => () => {},
      } as unknown as SubagentReadModel
      try {
        uiExtension(pi)
        await handlers.get("session_start")?.({ reason: "startup" }, ctx)
        await openSubagentTakeover(ctx, view, snapshot.id)
        const check = (layout: string) => {
          const lines = component!.render(80)
          const text = lines.join("\n")
          expect(lines).toHaveLength(29)
          expect(lines.every((line) => visibleWidth(line) <= 80)).toBe(true)
          if (layout === "minimal" || layout === "lite") {
            expect(text).toContain("  › Read demo.ts")
            expect(text).toContain("  ✓ read demo.ts · hello")
            expect(text).not.toContain("~ Checking file")
            expect(text).not.toContain("output:")
          } else {
            expect(text).toContain("> Read demo.ts")
            expect(text).toContain("~ Checking file")
            expect(text).toContain("→ read demo.ts")
            expect(text).toContain("output: hello")
          }
        }
        check(settings.expected)
        // Exercise both directions on the same already-open component.
        for (const layout of ["full", "minimal", "lite", "off", "lite"]) {
          await command!.handler(`layout ${layout}`, ctx)
          check(layout)
        }
        component!.invalidate()
      } finally {
        component?.dispose?.()
        await handlers.get("session_shutdown")?.({ reason: "quit" }, ctx)
        expect(ui.custom).toBe(custom)
        files.clear()
      }
    },
  )
})
