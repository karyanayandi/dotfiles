-- luacheck: globals vim

return {
  "navarasu/onedark.nvim",
  lazy = false,
  priority = 10000,
  config = function()
    require("onedark").setup()
    vim.cmd "colorscheme onedark"
  end,
}
