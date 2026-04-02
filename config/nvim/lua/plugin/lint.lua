-- TODO: add linting for github action, deno
-- luacheck: globals vim

return {
  "mfussenegger/nvim-lint",
  lazy = true,
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require "lint"

    local oxlint_root_files = {
      "oxlint.json",
      ".oxlintrc.json",
      "oxlint.config.js",
      "oxlint.config.ts",
      ".oxlint.json",
      ".oxlint.jsonc",
      "oxc.json",
    }
    local biome_root_files = { "biome.json", "biome.jsonc" }
    local deno_root_files = { "deno.json", "deno.jsonc" }
    local eslint_root_files = {
      ".eslintrc",
      ".eslintrc.json",
      ".eslintrc.js",
      "eslint.config.cjs",
      "eslint.config.js",
      "eslint.config.mjs",
    }

    local function has_any_file(files)
      for _, file in ipairs(files) do
        if vim.fn.glob(file) ~= "" then
          return true
        end
      end
      return false
    end

    local function javascript_linter()
      if has_any_file(oxlint_root_files) or vim.fn.glob "oxc.json" ~= "" then
        return { "oxlint" }
      elseif has_any_file(biome_root_files) then
        return { "biomejs" }
      elseif has_any_file(deno_root_files) then
        return { "deno" }
      elseif has_any_file(eslint_root_files) then
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
