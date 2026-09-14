import { deepStrictEqual, throws } from "node:assert"
import { test } from "node:test"
import { isModelShortcut } from "../index.ts"
import { nextThinkingLevel, parseShortcuts } from "./config.ts"

test("accepts Ctrl+number shortcuts", () => {
  deepStrictEqual(isModelShortcut("ctrl+1"), true)
  deepStrictEqual(isModelShortcut("ctrl+0"), true)
  deepStrictEqual(isModelShortcut("ctrl+shift+1"), false)
  deepStrictEqual(isModelShortcut("f1"), false)
})

test("cycles through model-supported thinking levels", () => {
  const extended = ["minimal", "low", "medium", "high", "xhigh", "max"] as const
  const limited = ["low", "high"] as const

  deepStrictEqual(nextThinkingLevel(extended, "max", 1), "minimal")
  deepStrictEqual(nextThinkingLevel(extended, "minimal", -1), "max")
  deepStrictEqual(nextThinkingLevel(limited, "low", 1), "high")
  deepStrictEqual(nextThinkingLevel(limited, "high", 1), "low")
})

test("parses shortcut thinking levels and legacy model strings", () => {
  deepStrictEqual(
    parseShortcuts({
      "ctrl+1": "anthropic/claude-sonnet",
      "ctrl+2": {
        model: "openai/gpt-5",
        thinkingLevel: "high",
      },
    }),
    {
      "ctrl+1": { model: "anthropic/claude-sonnet" },
      "ctrl+2": {
        model: "openai/gpt-5",
        thinkingLevel: "high",
      },
    },
  )

  throws(() =>
    parseShortcuts({
      "ctrl+1": { model: "openai/gpt-5", thinkingLevel: "invalid" },
    }),
  )
})
