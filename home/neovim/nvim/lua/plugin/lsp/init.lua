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
    },
    lazy = true,
    config = function()
      require("plugin.lsp.handlers").setup()
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
