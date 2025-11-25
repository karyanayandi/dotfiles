-- luacheck: globals vim

return {
	"RRethy/base16-nvim",
	lazy = false,
	priority = 1000,
	config = function()
		vim.cmd("colorscheme base16-gruvbox-dark-medium")
	end,
}
