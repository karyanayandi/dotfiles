return {
  "rmehri01/onenord.nvim",
  lazy = false,
  config = function()
    require("lualine").setup {
      borders = true,
      styles = {
        comments = "NONE",
        strings = "NONE",
        keywords = "NONE",
        functions = "NONE",
        variables = "NONE",
        diagnostics = "underline",
      },
      disable = {
        background = true,
        float_background = true,
        eob_lines = true,
      },
    }
  end,
}
