export function cacheRenderer(
  render: (width: number) => string[],
  invalidate: () => void,
) {
  let cachedWidth: number | undefined
  let cachedLines: string[] | undefined

  return {
    render(width: number) {
      if (cachedWidth === width && cachedLines) return cachedLines
      cachedWidth = width
      cachedLines = render(width)
      return cachedLines
    },
    invalidate() {
      cachedWidth = undefined
      cachedLines = undefined
      invalidate()
    },
  }
}
