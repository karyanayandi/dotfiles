return {
  "NvChad/nvim-colorizer.lua",
  lazy = false,
  event = "BufReadPre",
  config = function()
    require("colorizer").setup {
      filetypes = {
        "*",
        "!prompt",
        "!popup",
        "!lazy",
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
