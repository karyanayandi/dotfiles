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
        "rshkarin/mason-nvim-lint",
        "LittleEndianRoot/mason-conform",
        lazy = true,
      },
    },
    config = function()
      require "plugin.lsp.mason"
    end,
  },
}
