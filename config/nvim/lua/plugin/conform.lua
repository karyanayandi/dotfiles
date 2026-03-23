-- luacheck: globals vim

return {
  "stevearc/conform.nvim",
  lazy = true,
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local conform = require "conform"

    local formatter_cache = {}

    local function get_js_formatter()
      local cwd = vim.fn.getcwd()
      if formatter_cache[cwd] then
        return formatter_cache[cwd]
      end

      local formatter = { "oxfmt" }

      local function file_exists(path)
        return vim.fn.filereadable(path) == 1
      end

      if file_exists ".oxfmtrc.json" or file_exists ".oxfmtrc.jsonc" or file_exists "oxc.json" then
        formatter = { "oxfmt" }
      elseif file_exists "biome.json" or file_exists "biome.jsonc" then
        formatter = { "biome" }
      elseif file_exists "deno.json" or file_exists "deno.jsonc" then
        formatter = { "deno_fmt" }
      elseif
        file_exists ".prettierrc"
        or file_exists ".prettierrc.json"
        or file_exists ".prettierrc.js"
        or file_exists "prettier.config.js"
      then
        formatter = { "prettierd" }
      else
        local package_json = vim.fn.glob "package.json"
        if package_json ~= "" then
          local ok, content = pcall(vim.fn.readfile, package_json, "", 100)
          if ok and content then
            local json = table.concat(content, "\n")
            if json:match '"vite%-plus"' then
              formatter = { "oxfmt" }
            end
          end
        end
      end

      formatter_cache[cwd] = formatter
      return formatter
    end

    local formatters_by_ft = {
      astro = get_js_formatter,
      blade = { "blade-formatter" },
      c = { "clang_format" },
      css = { "prettierd" },
      go = { "gofumpt", "goimports-reviser", "golines" },
      graphql = { "prettierd" },
      html = { "prettierd" },
      javascript = get_js_formatter,
      javascriptreact = get_js_formatter,
      json = { "prettierd" },
      jsonc = { "prettierd" },
      json5 = { "prettierd" },
      lua = { "stylua" },
      markdown = get_js_formatter,
      nix = { "alejandra" },
      php = { "pretty-php" },
      python = { "isort", "black" },
      rust = { "rustfmt" },
      sh = { "shfmt" },
      svelte = get_js_formatter,
      typescript = get_js_formatter,
      typescriptreact = get_js_formatter,
      vue = get_js_formatter,
      yaml = { "prettierd", stop_after_first = true },
    }

    local function format_on_save(bufnr)
      if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
        return
      end
      return { timeout_ms = 3000, lsp_fallback = true, async = false }
    end

    conform.setup {
      formatters_by_ft = formatters_by_ft,
      format_on_save = format_on_save,
    }
  end,
}
