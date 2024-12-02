return {
  "rmehri01/onenord.nvim",
  lazy = false,
  config = function()
    require("onenord").setup {
      theme = nil,
      disable = {
        background = true,
        float_background = true,
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
