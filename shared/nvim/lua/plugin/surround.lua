return {
  {
    "kylechui/nvim-surround",
    version = "*",
    config = function()
      require("nvim-surround").setup {}
    end,
  },
  {
    "roobert/surround-ui.nvim",
    dependencies = {
      "kylechui/nvim-surround",
      "folke/which-key.nvim",
    },
    config = function()
      require("surround-ui").setup {
        root_key = "i",
      }
    end,
  },
}
