-- luacheck: globals vim

return {
	{
		"RRethy/base16-nvim",
		config = function()
			require("base16-colorscheme").setup({
				base00 = "#282c34",
				base01 = "#353b45",
				base02 = "#3e4451",
				base03 = "#545862",
				base04 = "#abb2bf",
				base05 = "#eceff4",
				base06 = "#c8ccd4",
				base07 = "#8fbcbb",
				base08 = "#88c0d0",
				base09 = "#81a1c1",
				base0A = "#5e81ac",
				base0B = "#bf616a",
				base0C = "#d08770",
				base0D = "#ebcb8b",
				base0E = "#a3be8c",
				base0F = "#b48ead",
			})
		end,
	},
	{
		"aurora-theme/nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("aurora").setup({
				theme = nil,
				fade_nc = true,
				disable = {
					background = true,
					float_background = true,
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
			})

			vim.cmd("colorscheme aurora")
		end,
	},
}
