import type { KeyId } from "@earendil-works/pi-tui"

const modifiers = ["ctrl", "shift", "alt", "super"] as const
const keys = new Set([
  ..."abcdefghijklmnopqrstuvwxyz0123456789`-=[]\\;',./!@#$%^&*()_+|~{}:<>?",
  "escape",
  "esc",
  "enter",
  "return",
  "tab",
  "space",
  "backspace",
  "delete",
  "insert",
  "clear",
  "home",
  "end",
  "pageUp",
  "pageDown",
  "up",
  "down",
  "left",
  "right",
  ...Array.from({ length: 12 }, (_, index) => `f${index + 1}`),
])

export function isShortcut(value: string): value is KeyId {
  const used = new Set<string>()
  let key = value

  while (true) {
    const modifier = modifiers.find((candidate) =>
      key.startsWith(`${candidate}+`),
    )
    if (!modifier) break
    if (used.has(modifier)) return false
    used.add(modifier)
    key = key.slice(modifier.length + 1)
  }

  return keys.has(key)
}
