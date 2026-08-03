import { defineConfig } from "vite-plus"

export default defineConfig({
  fmt: {
    bracketSpacing: true,
    jsxSingleQuote: false,
    printWidth: 80,
    proseWrap: "always",
    semi: false,
    singleQuote: false,
    tabWidth: 2,
    trailingComma: "all",
    experimentalTailwindcss: {
      functions: ["cn", "cva", "clsx"],
    },
    experimentalSortPackageJson: true,
    ignorePatterns: ["node_modules/**", "sessions/**", "extensions/**/docs/**"],
  },
  lint: {
    ignorePatterns: ["node_modules/**", "sessions/**", "assets/**"],
  },
  test: {
    include: ["**/*.spec.ts"],
  },
})
