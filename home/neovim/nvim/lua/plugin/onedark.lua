-- luacheck: globals vim

return {
  "olimorris/onedarkpro.nvim",
  lazy = false,
  priority = 10000,
  config = function()
    require("onedarkpro").setup()
    vim.cmd "colorscheme onedark"
  end,
}
