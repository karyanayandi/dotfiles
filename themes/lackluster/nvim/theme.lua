-- luacheck: globals vim

return {
	{
		"slugbyte/lackluster.nvim",
		lazy = false,
		priority = 1000,
		init = function()
			vim.cmd.colorscheme("lackluster")
		end,
	},
	{
		"RRethy/base16-nvim",
		lazy = true,
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
		"nvim-lualine/lualine.nvim",
		config = function()
			local colors = require("base16-colorscheme").colors

			local hide_in_width = function()
				return vim.fn.winwidth(0) > 80
			end

			local icons = require("config.icons")

			local branch = {
				"branch",
				icon = { icons.git.Branch, align = "left" },
				use_mode_colors = false,
				color = function()
					return { bg = colors.base03, fg = colors.base05, gui = "bold" }
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
					return { bg = colors.base03, fg = colors.base05 }
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
					return { bg = colors.base03, fg = colors.base05 }
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
					return { bg = colors.base03, fg = colors.base05 }
				end,
				update_in_insert = false,
				always_visible = false,
			}

			-- local filetype = {
			--   "filetype",
			--   icons_enabled = true,
			--   icon_only = false,
			--   color = function()
			--     return { bg = colors.base03, fg = colors.base05 }
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
