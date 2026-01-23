-- luacheck: globals vim

return {
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
	{
		"RRethy/base16-nvim",
		lazy = true,
		priority = 10,
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
		"nvim-lualine/lualine.nvim",
		config = function()
			local colors = require("aurora.colors").load()

			local hide_in_width = function()
				return vim.fn.winwidth(0) > 80
			end

			local icons = require("config.icons")

			local branch = {
				"branch",
				icon = { icons.git.Branch, align = "left" },
				use_mode_colors = false,
				color = function()
					return { bg = "#373b43", fg = colors.fg_light, gui = "bold" }
				end,
			}

			local diff = {
				"diff",
				symbols = {
					added = icons.git.Add,
					modified = icons.git.Mod,
					removed = icons.git.Remove,
				},
				colored = false,
				use_color_mode = true,
				diff_color = {
					added = "LuaLineDiffAdd",
					modified = "LuaLineDiffChange",
					removed = "LuaLineDiffDelete",
				},
				cond = hide_in_width,
				separator = "%#SLSeparator#" .. " " .. "%*",
				color = function()
					return { bg = "#373b43", fg = colors.fg_light }
				end,
			}

			local filename = {
				"filename",
				icons_enabled = true,
				symbols = {
					modified = "  ",
					readonly = "  ",
					unnamed = "  ",
					newfile = "  ",
				},
				cond = hide_in_width,
				path = 4,
				shorting_target = 10,
				use_color_mode = true,
				color = function()
					return { bg = "#373b43", fg = colors.fg_light }
				end,
			}

			local diagnostics = {
				"diagnostics",
				sources = { "nvim_diagnostic" },
				sections = { "error", "warn", "info", "hint" },
				symbols = {
					error = icons.diagnostics.Error .. "",
					warn = icons.diagnostics.Warning .. "",
					info = icons.diagnostics.Info .. "",
					hint = icons.diagnostics.Hint .. "",
				},
				colored = true,
				color = function()
					return { bg = "#32363e", fg = colors.fg_light }
				end,
				update_in_insert = false,
				always_visible = false,
			}

			-- local filetype = {
			--   "filetype",
			--   icons_enabled = true,
			--   icon_only = false,
			--   color = function()
			--     return { bg = "#252931", fg = colors.fg_light }
			--   end,
			-- }

			require("lualine").setup({
				options = {
					globalstatus = true,
					icons_enabled = true,
					theme = "auto",
					component_separators = { left = "", right = "" },
					section_separators = { left = "", right = "" },
					always_divide_middle = true,
					disabled_filetypes = {
						"NvimTree",
						"TelescopePrompt",
						"copilot-chat",
						"copilot-diff",
						"copilot-overlay",
						"dashboard",
						"gitcommit",
						"lazy",
						"nofile",
						"qf",
						"snacks_dashboard",
						"snacks_terminal",
						"spectre_panel",
						"undotree",
					},
					disable_buftypes = {
						"NvimTree",
						"TelescopePrompt",
						"copilot-chat",
						"copilot-diff",
						"copilot-overlay",
						"dashboard",
						"gitcommit",
						"lazy",
						"nofile",
						"qf",
						"snacks_dashboard",
						"snacks_terminal",
						"spectre_panel",
						"undotree",
					},
				},
				sections = {
					lualine_a = { branch, diff, filename },
					lualine_b = {},
					lualine_c = {},
					lualine_x = {},
					lualine_y = { diagnostics },
					-- lualine_z = { filetype, "location" },
					lualine_z = { "location" },
				},
				extensions = {},
			})
		end,
	},
}
