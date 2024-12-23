return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  opts = {
    render_modes = true,
  },

  config = function()
    require("render-markdown").setup {
      enabled = true,
    }
  end,
}
