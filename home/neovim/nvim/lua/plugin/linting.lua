-- TODO: add linting for github action, deno

return {
  "mfussenegger/nvim-lint",
  lazy = true,
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require "lint"

    lint.linters_by_ft = {
      javascript = { "eslint_d", "eslint" },
      typescript = { "eslint_d", "eslint" },
      javascriptreact = { "eslint_d", "eslint" },
      typescriptreact = { "eslint_d", "eslint" },
      astro = { "eslint_d", "eslint" },
      svelte = { "eslint_d", "eslint" },
      prisma = { "prisma-lint" },
      fish = { "fish" },
      go = { "golangcilint" },
      lua = { "luacheck" },
      php = { "php", "phpcs" },
      sh = { "shellcheck" },
      nix = { "nix" },
      json = { "jsonlint" },
      vue = { "eslint_d", "eslint" },
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
