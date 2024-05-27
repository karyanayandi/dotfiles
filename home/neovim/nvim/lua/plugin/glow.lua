return {
  "ellisonleao/glow.nvim",
  config = function()
    require("glow").setup {
      border = "shadow",
      pager = false,
      width = 120,
      height = 140,
      width_ratio = 0.7,
      height_ratio = 0.7,
    }
  end,
  cmd = "Glow",
}
