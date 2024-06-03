return {
  -- "karyanayandi/onenord.nvim",
  -- branch = "custom",
  "rmehri01/onenord.nvim",
  lazy = false,
  priority = 1001,
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
  vim.cmd.colorscheme('onenord')
}