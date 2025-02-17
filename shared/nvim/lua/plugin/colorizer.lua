return {
  "catgoose/nvim-colorizer.lua",
  lazy = false,
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
      buftypes = {},
      user_commands = true,
      lazy_load = false,
      user_default_options = {
        names = true,
        names_opts = {
          lowercase = true,
          camelcase = true,
          uppercase = false,
          strip_digits = false,
        },
        names_custom = false,
        RGB = true, -- #RGB hex codes
        RGBA = true, -- #RGBA hex codes
        RRGGBB = true, -- #RRGGBB hex codes
        RRGGBBAA = false, -- #RRGGBBAA hex codes
        AARRGGBB = true, -- 0xAARRGGBB hex codes
        rgb_fn = true, -- CSS rgb() and rgba() functions
        hsl_fn = true, -- CSS hsl() and hsla() functions
        css = true, -- Enable all CSS *features*:
        css_fn = false, -- Enable all CSS *functions*: rgb_fn, hsl_fn
        tailwind = true,
        tailwind_opts = {
          update_names = true,
        },
        sass = { enable = false, parsers = { "css" } },
        mode = "background",
        virtualtext = "■",
        virtualtext_inline = false,
        virtualtext_mode = "background",
        always_update = false,
        hooks = {
          do_lines_parse = false,
        },
      },
    }
  end,
}
