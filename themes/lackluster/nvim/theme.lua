-- luacheck: globals vim

return {
	{
		"RRethy/base16-nvim",
		priority = 10,
		config = function()
			require("base16-colorscheme").setup({
				base00 = "#0A0A0A",
				base01 = "#080808",
				base02 = "#444444",
				base03 = "#7A7A7A",
				base04 = "#DEEEED",
				base05 = "#DEEEED",
				base06 = "#DEEEED",
				base07 = "#708090",
				base08 = "#708090",
				base09 = "#7788AA",
				base0A = "#7788AA",
				base0B = "#D70000",
				base0C = "#FFAA88",
				base0D = "#FFAA88",
				base0E = "#789978",
				base0F = "#D7007D",
			})
		end,
	},
	{
		"slugbyte/lackluster.nvim",
		lazy = false,
		priority = 1000,
		init = function()
			vim.cmd.colorscheme("lackluster")
		end,
	},
}
