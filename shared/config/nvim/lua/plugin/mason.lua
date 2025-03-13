-- luacheck: globals vim

return {
  "williamboman/mason.nvim",
  cmd = "Mason",
  event = "BufReadPre",
  dependencies = {
    {
      "williamboman/mason-lspconfig.nvim",
      {
        "TabulateJarl8/mason-nvim-lint",
        branch = "patch-1",
      },
      "LittleEndianRoot/mason-conform",
      lazy = true,
    },
  },
  config = function()
    local icons = require "config.icons"

    local servers = {
      "astro",
      "bashls",
      "biome",
      "clangd",
      -- "denols",
      "docker_compose_language_service",
      "dockerls",
      "emmet_ls",
      "eslint",
      "golangci_lint_ls",
      "gopls",
      "html",
      "intelephense",
      "jsonls",
      "lua_ls",
      "marksman",
      -- "nil_ls",
      "prismals",
      "pyright",
      "rust_analyzer",
      "sqls",
      "svelte",
      "tailwindcss",
      "taplo",
      "templ",
      -- "ts_ls",
      "volar",
      "vtsls",
      "yamlls",
    }

    local formatters = {
      "alejandra",
      "biome",
      "black",
      "clang-format",
      "gofumpt",
      "goimports-reviser",
      "golines",
      "isort",
      "php-cs-fixer",
      "prettierd",
      "shfmt",
      "stylua",
    }

    local linters = {
      -- "biome",
      "flake8",
      "golangci-lint",
      "jsonlint",
      "luacheck",
      "markdownlint",
      "phpcs",
      "stylelint",
    }

    local settings = {
      ui = {
        border = "none",
        icons = {
          package_installed = icons.ui.Installed,
          package_pending = icons.ui.Pending,
          package_uninstalled = icons.ui.Uninstalled,
        },
      },
      log_level = vim.log.levels.INFO,
      max_concurrent_installers = 4,
    }

    require("mason").setup(settings)
    require("mason-lspconfig").setup {
      ensure_installed = servers,
      automatic_installation = true,
    }
    require("mason-conform").setup {
      ensure_installed = formatters,
      automatic_installation = false,
    }
    require("mason-nvim-lint").setup {
      ensure_installed = linters,
      ignore_install = { "eslint", "fish", "nix", "php", "python" },
      automatic_installation = true,
    }

    local lspconfig = require "lspconfig"

    for _, server in pairs(servers) do
      local opts = {
        on_attach = require("plugin.lsp").on_attach,
        capabilities = require("plugin.lsp").capabilities,
      }

      server = vim.split(server, "@")[1]

      local require_ok, conf_opts = pcall(require, "plugin.lsp.settings." .. server)
      if require_ok then
        opts = vim.tbl_deep_extend("force", conf_opts, opts)
      end

      lspconfig[server].setup(opts)
    end
  end,
}
