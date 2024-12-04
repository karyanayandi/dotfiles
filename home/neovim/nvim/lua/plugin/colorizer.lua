return {
  "NvChad/nvim-colorizer.lua",
  lazy = false,
  config = function()
    require("colorizer").setup {
      filetypes = {
        "*",
      },
      user_default_options = {
        names = false,
        rgb_fn = true,
        hsl_fn = true,
        tailwind = "both",
        RRGGBBAA = true,
        AARRGGBB = true,
        always_update = true,
      },
      buftypes = {},
    }
  end,
}
