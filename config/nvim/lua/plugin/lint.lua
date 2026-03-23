-- TODO: add linting for github action, deno
-- luacheck: globals vim

return {
  "mfussenegger/nvim-lint",
  lazy = true,
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require "lint"

    local linter_cache = {}

    local function get_js_linter()
      local cwd = vim.fn.getcwd()
      if linter_cache[cwd] then
        return linter_cache[cwd]
      end

      local linter = { "oxlint" }

      local function file_exists(path)
        return vim.fn.filereadable(path) == 1
      end

      if
        file_exists "oxlint.json"
        or file_exists ".oxlintrc.json"
        or file_exists "oxlint.config.js"
        or file_exists "oxlint.config.ts"
        or file_exists ".oxlint.json"
        or file_exists ".oxlint.jsonc"
        or file_exists "oxc.json"
      then
        linter = { "oxlint" }
      elseif file_exists "biome.json" or file_exists "biome.jsonc" then
        linter = { "biomejs" }
      elseif file_exists "deno.json" or file_exists "deno.jsonc" then
        linter = { "deno" }
      elseif
        file_exists ".eslintrc"
        or file_exists ".eslintrc.json"
        or file_exists ".eslintrc.js"
        or file_exists "eslint.config.cjs"
        or file_exists "eslint.config.js"
        or file_exists "eslint.config.mjs"
      then
        linter = { "eslint_d" }
      else
        local package_json = vim.fn.glob "package.json"
        if package_json ~= "" then
          local ok, content = pcall(vim.fn.readfile, package_json, "", 100)
          if ok and content then
            local json = table.concat(content, "\n")
            if json:match '"vite%-plus"' then
              linter = { "oxlint" }
            end
          end
        end
      end

      linter_cache[cwd] = linter
      return linter
    end

    lint.linters_by_ft = {
      astro = get_js_linter(),
      css = { "eslint_d" },
      fish = { "fish" },
      javascript = get_js_linter(),
      javascriptreact = get_js_linter(),
      lua = { "luacheck" },
      markdown = { "vale" },
      sh = { "shellcheck" },
      nix = { "nix" },
      php = { "php" },
      python = { "python", "flake8" },
      rust = { "clippy" },
      svelte = get_js_linter(),
      typescript = get_js_linter(),
      typescriptreact = get_js_linter(),
      vue = get_js_linter(),
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
