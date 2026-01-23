-- luacheck: globals vim

return {
	{
		"RRethy/base16-nvim",
		priority = 10,
		config = function()
			require("base16-colorscheme").setup({
				base00 = "#282828",
				base01 = "#32302f",
				base02 = "#3c3836",
				base03 = "#504945",
				base04 = "#7c6f64",
				base05 = "#d4be98",
				base06 = "#e6d5ae",
				base07 = "#fbf1c7",
				base08 = "#bdae93",
				base09 = "#a89984",
				base0A = "#c0b090",
				base0B = "#8f8a7a",
				base0C = "#9c9484",
				base0D = "#b0a890",
				base0E = "#c8bfa5",
				base0F = "#6f655b",
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
