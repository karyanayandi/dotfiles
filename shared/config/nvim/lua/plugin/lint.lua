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

    local function lint_for_js_or_ts()
      return has_deno_json() and { "deno" } or { "eslint_d" }
    end

    lint.linters_by_ft = {
      astro = lint_for_js_or_ts(),
      css = { "stylelint", "eslint_d" },
      fish = { "fish" },
      go = { "golangcilint" },
      javascript = lint_for_js_or_ts(),
      javascriptreact = lint_for_js_or_ts(),
      json = { "jsonlint" },
      lua = { "luacheck" },
      markdown = { "markdownlint" },
      nix = { "nix" },
      php = { "php", "phpcs" },
      python = { "python", "flake8" },
      -- sh = { "shellcheck" },
      svelte = lint_for_js_or_ts(),
      typescript = lint_for_js_or_ts(),
      typescriptreact = lint_for_js_or_ts(),
      vue = lint_for_js_or_ts(),
      yaml = { "yamllint" },
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
