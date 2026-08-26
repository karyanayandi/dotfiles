import { describe, expect, test } from "vitest"

import { displayThinkingLevel } from "./index.js"

describe("displayThinkingLevel", () => {
  test("uses GPT-5.6 Codex labels", () => {
    const model = { provider: "openai-codex", id: "gpt-5.6-luna" }

    expect(displayThinkingLevel(model, "minimal")).toBe("light")
    expect(displayThinkingLevel(model, "xhigh")).toBe("extra high")
    expect(displayThinkingLevel(model, "max")).toBe("ultra")
  })

  test("keeps labels for other models", () => {
    expect(
      displayThinkingLevel({ provider: "openai-codex", id: "gpt-5.5" }, "max"),
    ).toBe("max")
    expect(displayThinkingLevel(undefined, "high")).toBe("high")
  })
})
