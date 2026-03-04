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
        "!codecompanion",
      },
      buftypes = {},
      user_commands = true,
      lazy_load = false,
      options = {
        parsers = {
          names = {
            enable = true,
            lowercase = true,
            camelcase = true,
            uppercase = false,
            strip_digits = false,
            custom = false,
          },
          hex = {
            default = true,
            rgb = true,
            rgba = true,
            rrggbb = true,
            rrggbbaa = true,
            hash_aarrggbb = true,
            aarrggbb = true,
            no_hash = true,
          },
          rgb = { enable = true },
          hsl = { enable = true },
          oklch = { enable = true },
          tailwind = {
            enable = true,
            lsp = true,
            update_names = true,
          },
          sass = {
            enable = false,
            parsers = { css = true },
            variable_pattern = "^%$([%w_-]+)",
          },
          xterm = { enable = true },
          xcolor = { enable = true },
          hsluv = { enable = false },
          css_var_rgb = { enable = true },
          css_var_hsl = { enable = true },
          css_var_oklch = { enable = true },
          custom = {},
        },
        display = {
          mode = "background",
          background = {
            bright_fg = "#000000",
            dark_fg = "#ffffff",
          },
          virtualtext = {
            char = "■",
            position = "eol",
            hl_mode = "foreground",
          },
          priority = {
            default = 150,
            lsp = 200,
          },
        },
        hooks = {
          do_lines_parse = false,
          should_highlight_line = false,
        },
        always_update = false,
        debounce_ms = 0,
      },
    }
  end,
}
