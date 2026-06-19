-- TODO: add linting for github action, deno
-- luacheck: globals vim

return {
  "mfussenegger/nvim-lint",
  lazy = true,
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require "lint"

    require("lint").linters.vp_lint = {
      cmd = function()
        local local_binary = vim.fn.fnamemodify("./node_modules/.bin/vp", ":p")
        return vim.loop.fs_stat(local_binary) and local_binary or "vp"
      end,
      args = { "lint", "--format", "github" },
      stdin = false,
      stream = "stdout",
      ignore_exitcode = true,
      parser = (require "lint.parser").from_pattern(
        "::([^ ]+) file=(.*),line=(%d+),endLine=(%d+),col=(%d+),endColumn=(%d+),title=(.*)::(.*)",
        { "severity", "file", "lnum", "end_lnum", "col", "end_col", "code", "message" },
        { error = vim.diagnostic.severity.ERROR, warning = vim.diagnostic.severity.WARN },
        { source = "vp-lint" },
        {}
      ),
    }

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

    local function has_vite_plus()
      if vim.fn.glob "vite.config.ts" ~= "" then
        if vim.fn.glob "package.json" ~= "" then
          local pkg = vim.fn.readfile "package.json"
          if pkg and #pkg > 0 then
            local content = table.concat(pkg, "\n")
            if content:find "vite%-plus" then
              return true
            end
          end
        end
      end
      return false
    end

    local function javascript_linter()
      if has_vite_plus() then
        return { "vp_lint" }
      elseif has_any_file(oxlint_root_files) or vim.fn.glob "oxc.json" ~= "" then
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

    local js_linter = javascript_linter()

    lint.linters_by_ft = {
      astro = js_linter,
      css = js_linter,
      fish = { "fish" },
      javascript = js_linter,
      javascriptreact = js_linter,
      lua = { "luacheck" },
      markdown = { "vale" },
      sh = { "shellcheck" },
      nix = { "nix" },
      php = { "php" },
      python = { "python", "flake8" },
      rust = { "clippy" },
      svelte = js_linter,
      typescript = js_linter,
      typescriptreact = js_linter,
      vue = js_linter,
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
