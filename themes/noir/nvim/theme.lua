-- luacheck: globals vim

return {
	{
		"RRethy/base16-nvim",
		lazy = false,
		priority = 1000,
		config = function()
			-- Noir color palette
			local noir_colors = {
				base00 = "#0c0b0a", -- Default Background
				base01 = "#0d0b0a", -- Lighter Background
				base02 = "#171513", -- Selection Background
				base03 = "#282a2d", -- Comments, Invisibles
				base04 = "#a0a4a8", -- Dark Foreground
				base05 = "#a0a4a8", -- Default Foreground
				base06 = "#9aa0a6", -- Light Foreground
				base07 = "#80868b", -- Lightest Foreground
				base08 = "#916666", -- Variables, XML Tags
				base09 = "#8a8080", -- Integers, Booleans
				base0A = "#8a8080", -- Classes, Markup Bold
				base0B = "#949669", -- Strings, Markup Code
				base0C = "#80a8a2", -- Support, Regex
				base0D = "#7691a3", -- Functions, Methods
				base0E = "#9486a3", -- Keywords, Storage
				base0F = "#5a6b75", -- Deprecated
			}
			require("base16-colorscheme").setup(noir_colors)
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
				colored = true,
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
						"fzf",
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
						"fzf",
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
					lualine_z = { "location" },
				},
				extensions = {},
			})
		end,
	},
}
