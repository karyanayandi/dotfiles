import { defineConfig } from "oxfmt"

export default defineConfig({
  bracketSpacing: true,
  jsxSingleQuote: false,
  printWidth: 80,
  proseWrap: "always",
  semi: false,
  singleQuote: false,
  tabWidth: 2,
  trailingComma: "all",
  sortTailwindcss: {
    functions: ["cn", "cva", "clsx"],
  },
  sortPackageJson: true,
  ignorePatterns: ["node_modules/**", "sessions/**", "extensions/**/docs/**"],
})
