import baseConfig from "@yopem/oxlint-config"
import { defineConfig } from "oxlint"

export default defineConfig({
  extends: [baseConfig],
  ignorePatterns: ["node_modules/**", "sessions/**", "assets/**"],
})
