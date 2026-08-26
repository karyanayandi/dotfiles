import { describe, expect, test } from "vitest"

import { effectiveThinkingLevel } from "./index.js"

describe("effectiveThinkingLevel", () => {
  test("shows model-mapped provider effort", () => {
    expect(
      effectiveThinkingLevel(
        { thinkingLevelMap: { minimal: "low" } },
        "minimal",
      ),
    ).toBe("low")
  })

  test("keeps standard and unmapped levels", () => {
    expect(effectiveThinkingLevel(undefined, "high")).toBe("high")
    expect(
      effectiveThinkingLevel({ thinkingLevelMap: { off: null } }, "off"),
    ).toBe("off")
  })
})
