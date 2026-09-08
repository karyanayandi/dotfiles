import { describe, expect, test } from "vitest"

import { displayThinkingLevel } from "./index.js"

describe("displayThinkingLevel", () => {
  test.each(["gpt-5.6-luna", "gpt-6-astra"])(
    "uses Codex labels for %s",
    (id) => {
      const model = { provider: "openai-codex", id }

      expect(displayThinkingLevel(model, "minimal")).toBe("light")
      expect(displayThinkingLevel(model, "xhigh")).toBe("extra high")
      expect(displayThinkingLevel(model, "max")).toBe("ultra")
    },
  )

  test("keeps labels for other models", () => {
    expect(
      displayThinkingLevel({ provider: "openai-codex", id: "gpt-5.5" }, "max"),
    ).toBe("max")
    expect(displayThinkingLevel(undefined, "high")).toBe("high")
  })
})
