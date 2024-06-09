return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      {
        "b0o/SchemaStore.nvim",
        version = false,
        config = function()
          require "plugin.lsp.settings.jsonls"
        end,
      },
      {
        "folke/neoconf.nvim",
        cmd = "Neoconf",
        config = true,
      },
      {
        "folke/neodev.nvim",
        opts = {
          experimental = {
            pathStrict = true,
          },
        },
      },
    },
    lazy = true,
    config = function()
      local M = {}

      M.server_capabilities = function()
        local active_clients = vim.lsp.get_clients()
        local active_client_map = {}

        for index, value in ipairs(active_clients) do
          active_client_map[value.name] = index
        end

        vim.ui.select(vim.tbl_keys(active_client_map), {
          prompt = "Select client:",
          format_item = function(item)
            return "capabilites for: " .. item
          end,
        }, function(choice)
          print(vim.inspect(vim.lsp.get_clients()[active_client_map[choice]].server_capabilities))
        end)
      end

      require("plugin.lsp.handlers").setup()

      return M
    end,
  },
  {
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
      require "plugin.lsp.mason"
    end,
  },
}
