-- luacheck: globals vim

return {
  "soulsam480/nvim-oxlint",
  lazy = true,
  ft = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte", "astro" },
  config = function()
    require("oxlint").setup {
      config_path = function()
        -- Search for oxlint config files
        if vim.fn.glob "oxlint.json" ~= "" then
          return "oxlint.json"
        elseif vim.fn.glob "oxlint.config.js" ~= "" then
          return "oxlint.config.js"
        elseif vim.fn.glob "oxlint.config.ts" ~= "" then
          return "oxlint.config.ts"
        elseif vim.fn.glob ".oxlint.json" ~= "" then
          return ".oxlint.json"
        elseif vim.fn.glob ".oxlint.jsonc" ~= "" then
          return ".oxlint.jsonc"
        elseif vim.fn.glob "oxc.json" ~= "" then
          return "oxc.json"
        end
        return nil
      end,
    }
  end,
}
