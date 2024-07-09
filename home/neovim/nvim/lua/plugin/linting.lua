-- TODO: add linting for github action, deno

return {
  "mfussenegger/nvim-lint",
  lazy = true,
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require "lint"

    lint.linters_by_ft = {
      javascript = { "eslint_d" },
      typescript = { "eslint_d" },
      javascriptreact = { "eslint_d" },
      typescriptreact = { "eslint_d" },
      astro = { "eslint_d" },
      svelte = { "eslint_d" },
      prisma = { "prisma-lint" },
      fish = { "fish" },
      go = { "golangcilint" },
      lua = { "luacheck" },
      php = { "php", "phpcs" },
      sh = { "shellcheck" },
      nix = { "nix" },
      json = { "jsonlint" },
      vue = { "eslint_d" },
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

    vim.keymap.set({ "n" }, "<leader>lL", toggle_lint, { noremap = true, desc = "Toggle linting for current file" })
  end,
}
