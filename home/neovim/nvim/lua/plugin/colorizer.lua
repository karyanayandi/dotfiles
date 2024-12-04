return {
  "NvChad/nvim-colorizer.lua",
  lazy = false,
  config = function()
    require("colorizer").setup {
      filetypes = {
        "*",
      },
      user_default_options = {
        AARRGGBB = true,
        RRGGBBAA = true,
        always_update = true,
        css = false,
        css_fn = false,
        hsl_fn = true,
        names = false,
        rgb_fn = true,
        tailwind = "both",
      },
      buftypes = {},
    }
  end,
}
