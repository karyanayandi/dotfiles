return {
  "antosha417/nvim-lsp-file-operations",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-tree.lua",
  },
  config = function()
    require("lsp-file-operations").setup {
      operations = {
        willRenameFiles = true,
        didRenameFiles = true,
        willCreateFiles = true,
        didCreateFiles = true,
        willDeleteFiles = true,
        didDeleteFiles = true,
      },
    }
  end,
}
