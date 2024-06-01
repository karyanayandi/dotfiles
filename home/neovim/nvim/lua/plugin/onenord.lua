return {
  "karyanayandi/onenord.nvim",
  branch = "custom",
  lazy = false,
  -- priority = 1000,
  config = function()
    require("onenord").setup {
      theme = "dark",
      borders = true,
      fade_nc = false,
      styles = {
        comments = "NONE",
        strings = "NONE",
        keywords = "NONE",
        functions = "italic",
        variables = "NONE",
        diagnostics = "underline",
      },
      disable = {
        background = false,
        cursorline = false,
        eob_lines = true,
      },
      inverse = {
        match_paren = false,
      },
      custom_highlights = {},
      custom_colors = {},
    }
  end,
}
