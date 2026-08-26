import {
  DynamicBorder,
  type ExtensionContext,
} from "@earendil-works/pi-coding-agent"
import {
  Container,
  decodeKittyPrintable,
  Key,
  matchesKey,
  type SelectItem,
  SelectList,
  Text,
} from "@earendil-works/pi-tui"

export async function pick(
  ctx: ExtensionContext,
  title: string,
  items: SelectItem[],
) {
  return ctx.ui.custom<string | null>((tui, theme, _keybindings, done) => {
    const container = new Container()
    let query = ""
    const queryText = new Text("", 1, 0)
    const listTheme = {
      selectedPrefix: (text: string) => theme.fg("accent", text),
      selectedText: (text: string) => theme.fg("accent", text),
      description: (text: string) => theme.fg("muted", text),
      scrollInfo: (text: string) => theme.fg("dim", text),
      noMatch: (text: string) => theme.fg("warning", text),
    }

    let list: SelectList
    const updateList = () => {
      const terms = query.toLowerCase().split(/\s+/).filter(Boolean)
      const filtered = items.filter((item) => {
        const text =
          `${item.label} ${item.value} ${item.description ?? ""}`.toLowerCase()
        return terms.every((term) => text.includes(term))
      })
      list = new SelectList(
        filtered,
        Math.min(Math.max(filtered.length, 1), 12),
        listTheme,
      )
      list.onSelect = (item) => done(item.value)
      list.onCancel = () => done(null)
      queryText.setText(theme.fg("muted", `Search: ${query || "_"}`))
    }
    updateList()

    container.addChild(
      new DynamicBorder((text: string) => theme.fg("accent", text)),
    )
    container.addChild(new Text(theme.fg("accent", theme.bold(title)), 1, 0))
    container.addChild(queryText)
    const listComponent = {
      render: (width: number) => list.render(width),
      invalidate: () => list.invalidate(),
      handleInput(data: string) {
        const isPrintable = [...data].every((character) => {
          const codePoint = character.codePointAt(0) ?? 0
          return codePoint >= 32 && codePoint !== 127
        })
        const printable =
          decodeKittyPrintable(data) ?? (isPrintable ? data : undefined)
        if (printable) {
          query += printable
          updateList()
        } else if (matchesKey(data, Key.backspace)) {
          query = query.slice(0, -1)
          updateList()
        } else {
          list.handleInput(data)
        }
      },
    }
    container.addChild(listComponent)
    container.addChild(
      new Text(
        theme.fg(
          "dim",
          "type to search • ↑↓ navigate • enter select • esc cancel",
        ),
        1,
        0,
      ),
    )
    container.addChild(
      new DynamicBorder((text: string) => theme.fg("accent", text)),
    )

    return {
      render(width: number) {
        return container.render(width)
      },
      invalidate() {
        container.invalidate()
      },
      handleInput(data: string) {
        listComponent.handleInput(data)
        tui.requestRender()
      },
    }
  })
}
