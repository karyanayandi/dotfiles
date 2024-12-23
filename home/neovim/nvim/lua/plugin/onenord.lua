return {
  "rmehri01/onenord.nvim",
  lazy = false,
  config = function()
    require("onenord").setup {
      theme = nil,
      fade_nc = false,
      disable = {
        background = true,
        float_background = true,
        cursorline = true,
        eob_lines = true,
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
