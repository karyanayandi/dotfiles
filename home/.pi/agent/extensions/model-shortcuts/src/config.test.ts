import { deepStrictEqual, throws } from "node:assert"
import { test } from "node:test"
import { parseShortcuts } from "./config.ts"

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
