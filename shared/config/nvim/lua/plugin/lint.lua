-- luacheck: globals vim
-- TODO: add linting for github action, deno

return {
  "mfussenegger/nvim-lint",
  lazy = true,
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require "lint"

    local function has_deno_json()
      return vim.fn.glob "deno.json" ~= ""
    end

    lint.linters_by_ft = {
      astro = has_deno_json() and { "deno" } or { "eslint_d" },
      fish = { "fish" },
      go = { "golangcilint" },
      javascript = has_deno_json() and { "deno" } or { "eslint_d" },
      javascriptreact = has_deno_json() and { "deno" } or { "eslint_d" },
      json = { "jsonlint" },
      lua = { "luacheck" },
      nix = { "nix" },
      php = { "php", "phpcs" },
      -- sh = { "shellcheck" },
      svelte = has_deno_json() and { "deno" } or { "eslint_d" },
      typescript = has_deno_json() and { "deno" } or { "eslint_d" },
      typescriptreact = has_deno_json() and { "deno" } or { "eslint_d" },
      vue = has_deno_json() and { "deno" } or { "eslint_d" },
    }

    local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
      group = lint_augroup,
      callback = function()
        lint.try_lint()
      end,
    })

    vim.keymap.set("n", "<leader>ll", function()
      lint.try_lint()
    end, { desc = "Trigger linting for current file" })
  end,
}
