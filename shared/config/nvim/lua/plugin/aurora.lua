-- luacheck: globals vim

return {
  "aurora-theme/nvim",
  lazy = false,
  priority = 1000,
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

    vim.cmd "colorscheme aurora"
  end,
}
