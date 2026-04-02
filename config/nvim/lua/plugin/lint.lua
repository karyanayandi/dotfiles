-- TODO: add linting for github action, deno
-- luacheck: globals vim

return {
  "mfussenegger/nvim-lint",
  lazy = true,
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require "lint"

    local function javascript_linter()
      if
        vim.fn.glob "oxlint.json" ~= ""
        or vim.fn.glob ".oxlintrc.json" ~= ""
        or vim.fn.glob "oxlint.config.js" ~= ""
        or vim.fn.glob "oxlint.config.ts" ~= ""
        or vim.fn.glob ".oxlint.json" ~= ""
        or vim.fn.glob ".oxlint.jsonc" ~= ""
        or vim.fn.glob "oxc.json" ~= ""
      then
        return { "oxlint" }
      elseif vim.fn.glob "biome.json" ~= "" or vim.fn.glob "biome.jsonc" ~= "" then
        return { "biomejs" }
      elseif vim.fn.glob "deno.json" ~= "" or vim.fn.glob "deno.jsonc" ~= "" then
        return { "deno" }
      elseif
        vim.fn.glob ".eslintrc" ~= ""
        or vim.fn.glob ".eslintrc.json" ~= ""
        or vim.fn.glob ".eslintrc.js" ~= ""
        or vim.fn.glob "eslint.config.cjs" ~= ""
        or vim.fn.glob "eslint.config.js" ~= ""
        or vim.fn.glob "eslint.config.mjs" ~= ""
      then
        return { "eslint_d" }
      else
        return { "oxlint" }
      end
    end

    lint.linters_by_ft = {
      astro = javascript_linter(),
      css = javascript_linter(),
      fish = { "fish" },
      javascript = javascript_linter(),
      javascriptreact = javascript_linter(),
      lua = { "luacheck" },
      markdown = { "vale" },
      sh = { "shellcheck" },
      nix = { "nix" },
      php = { "php" },
      python = { "python", "flake8" },
      rust = { "clippy" },
      svelte = javascript_linter(),
      typescript = javascript_linter(),
      typescriptreact = javascript_linter(),
      vue = javascript_linter(),
    }

    local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

    vim.api.nvim_create_autocmd({
      "BufEnter",
      "BufWinEnter",
      "BufRead",
      "BufReadPost",
      "BufNewFile",
      "BufAdd",
      "BufCreate",
      "FileType",
      "WinEnter",
      "TabEnter",
      "FocusGained",
      "VimEnter",
      "SessionLoadPost",
    }, {
      group = lint_augroup,
      callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        local filename = vim.fn.bufname(bufnr)
        local filetype = vim.bo[bufnr].filetype

        local bufname = vim.api.nvim_buf_get_name(bufnr)

        if filetype == "markdown" then
          if
            bufname:match "codecompanion"
            or bufname:match "CodeCompanion"
            or bufname:match "Avante"
            or bufname:match "copilot%-"
          then
            lint.linters_by_ft["markdown"] = {}
          else
            lint.linters_by_ft["markdown"] = { "vale" }
          end
        end

        if filetype == "sh" then
          if filename:match "%.env$" then
            lint.linters_by_ft["sh"] = {}
          else
            lint.linters_by_ft["sh"] = { "shellcheck" }
          end
        end
      end,
    })

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
