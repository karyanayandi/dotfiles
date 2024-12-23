return {
  "karyanayandi/aurora.nvim",
  lazy = false,
  config = function()
    require("aurora").setup {
      theme = nil,
      fade_nc = false,
      disable = {
        background = false,
        float_background = false,
        cursorline = true,
        eob_lines = false,
      },
      borders = true,
      styles = {
        comments = "italic",
        strings = "NONE",
        keywords = "NONE",
        functions = "NONE",
        variables = "NONE",
        diagnostics = "underline",
      },
    }
  end,
}
