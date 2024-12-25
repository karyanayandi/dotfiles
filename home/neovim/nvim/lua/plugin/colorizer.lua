return {
  "catgoose/nvim-colorizer.lua",
  lazy = false,
  commit = "4acf88d31b3a7a1a7f31e9c30bf2b23c6313abdb",
  event = "BufReadPre",
  config = function()
    require("colorizer").setup {
      filetypes = {
        "*",
        "!prompt",
        "!popup",
        "!lazy",
        "!nofile",
        "!snacks_dashboard",
        "!snacks_terminal",
        "!copilot-chat",
        "!copilot-diff",
        "!copilot-overlay",
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
