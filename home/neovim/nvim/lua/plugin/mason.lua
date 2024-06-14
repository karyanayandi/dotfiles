return {
  "williamboman/mason.nvim",
  cmd = "Mason",
  event = "BufReadPre",
  dependencies = {
    {
      "williamboman/mason-lspconfig.nvim",
      lazy = true,
    },
  },
  config = function()
    local servers = {
      "astro",
      "clangd",
      "bashls",
      "cssls",
      "gopls",
      "html",
      "jsonls",
      "lua_ls",
      "nil_ls",
      "pyright",
      "svelte",
      "tailwindcss",
      "tsserver",
      "yamlls",
      -- "rust_analyzer",
      -- "deno",
      -- "stylua",
      -- "shellcheck",
      -- "shfmt",
      -- "flake8",
    }


    local icons = require "config.icons"

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

    local lspconfig = require "lspconfig"

    local opts = {}

    for _, server in pairs(servers) do
      opts = {
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