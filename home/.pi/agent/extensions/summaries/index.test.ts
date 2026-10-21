import assert from "node:assert/strict"
import { mkdtemp, rm } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join } from "node:path"
import { setTimeout as delay } from "node:timers/promises"
import test from "node:test"
import {
  DefaultResourceLoader,
  SettingsManager,
} from "@earendil-works/pi-coding-agent"
import summariesExtension from "./index.ts"

function createDeferredRejection() {
  let rejectPromise: (reason?: unknown) => void = () => undefined
  const promise = new Promise<never>((_resolve, reject) => {
    rejectPromise = reject
  })

  return { promise, reject: rejectPromise }
}

test("registers only the recap renderer, command, and bounded lifecycle hooks", () => {
  const events = new Set<string>()
  const renderers = new Set<string>()
  const commands = new Set<string>()

  const api = {
    on(event: string) {
      events.add(event)

      return () => events.delete(event)
    },
    registerEntryRenderer: (customType: string) => renderers.add(customType),
    registerCommand: (name: string) => commands.add(name),
    appendEntry() {
      throw new Error("Registration must not append session entries")
    },
  } satisfies Parameters<typeof summariesExtension>[0]

  summariesExtension(api)

  assert.deepEqual(
    events,
    new Set([
      "session_start",
      "before_agent_start",
      "agent_settled",
      "session_shutdown",
    ]),
  )
  assert.deepEqual(renderers, new Set(["summary-recap"]))
  assert.deepEqual(commands, new Set(["summary-model"]))
})

test(
  "shows and clears the run indicator above the editor through its lifecycle",
  { timeout: 10_000 },
  async () => {
    const directory = await mkdtemp(join(tmpdir(), "pi-summaries-widget-"))
    const widgets: {
      key: string
      content: string[] | undefined
      placement: string | undefined
    }[] = []
    const notifications: { message: string; type: string | undefined }[] = []
    const entries: { type: string; data: unknown }[] = []
    const completionAuth = createDeferredRejection()
    const shutdownAuth = createDeferredRejection()
    const authRequests = [completionAuth.promise, shutdownAuth.promise]
    let resolveAppend: () => void = () => undefined
    const appended = new Promise<void>((resolve) => {
      resolveAppend = resolve
    })
    let emit: ((event: string) => Promise<void>) | undefined

    const loader = new DefaultResourceLoader({
      cwd: directory,
      agentDir: join(directory, "agent"),
      settingsManager: SettingsManager.inMemory(undefined, {
        projectTrusted: false,
      }),
      extensionFactories: [summariesExtension],
    })

    try {
      await loader.reload()
      const loaded = loader.getExtensions()
      assert.deepEqual(loaded.errors, [])
      const extension = loaded.extensions[0]
      assert.ok(extension)
      loaded.runtime.appendEntry = (type, data) => {
        entries.push({ type, data })
        resolveAppend()
      }
      emit = async (event) => {
        for (const handler of extension.handlers.get(event) ?? [])
          await handler({ type: event }, ctx)
      }

      const ctx = {
        mode: "tui",
        hasUI: true,
        ui: {
          theme: {
            fg: (color: string, text: string) => `${color}:${text}`,
          },
          setStatus: () =>
            assert.fail("The indicator must not use footer status"),
          setWidget: (
            key: string,
            content: string[] | undefined,
            options?: { placement?: string },
          ) => {
            widgets.push({ key, content, placement: options?.placement })
          },
          notify: (message: string, type?: string) => {
            notifications.push({ message, type })
          },
        },
        sessionManager: {
          getLeafId: () => null,
          getBranch: () => [
            {
              type: "message",
              id: "run-1",
              message: {
                role: "assistant",
                content: [{ type: "text", text: "Finished work." }],
              },
            },
          ],
        },
        modelRegistry: {
          find: () => ({}),
          getApiKeyAndHeaders: () => {
            const request = authRequests.shift()
            if (!request) throw new Error("Unexpected summary model request")
            return request
          },
        },
      }

      await emit("session_start")
      await emit("before_agent_start")
      await emit("agent_settled")
      assert.deepEqual(widgets.at(-1), {
        key: "summaries",
        content: ["muted:✦ summarizing run…"],
        placement: "aboveEditor",
      })

      completionAuth.reject(new Error("offline"))
      await appended
      await delay(0)
      assert.equal(entries.length, 1)
      assert.equal(notifications.at(-1)?.type, "warning")
      assert.deepEqual(widgets.at(-1), {
        key: "summaries",
        content: undefined,
        placement: "aboveEditor",
      })

      await emit("before_agent_start")
      await emit("agent_settled")
      assert.deepEqual(widgets.at(-1), {
        key: "summaries",
        content: ["muted:✦ summarizing run…"],
        placement: "aboveEditor",
      })

      const shutdown = emit("session_shutdown")
      shutdownAuth.reject(new Error("shutdown"))
      await shutdown
      await delay(0)
      assert.deepEqual(widgets.at(-1), {
        key: "summaries",
        content: undefined,
        placement: "aboveEditor",
      })
      assert.equal(entries.length, 1)
    } finally {
      completionAuth.reject(new Error("test cleanup"))
      shutdownAuth.reject(new Error("test cleanup"))
      await emit?.("session_shutdown")
      await rm(directory, { recursive: true, force: true })
    }
  },
)
