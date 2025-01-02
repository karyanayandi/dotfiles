-- luacheck: globals vim

return {
  "b0o/incline.nvim",
  event = "BufReadPre",
  enabled = true,
  config = function()
    require("incline").setup {
      highlight = {
        groups = {
          InclineNormal = { guibg = "#252931", guifg = "#E5E9F0" },
          InclineNormalNC = { guifg = "#252931", guibg = "#E5E9F0" },
        },
      },
      window = { margin = { vertical = 0, horizontal = 1 } },
      render = function(props)
        local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
        return { { " " }, { filename } }
      end,
    }
  end,
}
