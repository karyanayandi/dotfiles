return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  config = function()
    require("catppuccin").setup {
      flavor = "mocha",
      transparent_background = true,
      custom_highlights = function(colors)
        return {
          NvimTreeNormal = { bg = "NONE", fg = colors.text },
        }
      end,
    }
  end,
}
