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
        {
          "TabulateJarl8/mason-nvim-lint",
          branch = "patch-1",
        },
        "LittleEndianRoot/mason-conform",
        lazy = true,
      },
    },
    config = function()
      require "plugin.lsp.mason"
    end,
  },
}
