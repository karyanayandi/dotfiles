-- luacheck: globals vim

return {
	{
		"oskarnurm/koda.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			local koda = require("koda")
			local colors = koda.get_palette("light")

			vim.api.nvim_set_hl(0, "BlinkCmpDoc", { bg = colors.line, fg = colors.highlight })
			vim.api.nvim_set_hl(0, "BlinkCmpDocBorder", { bg = colors.line, fg = colors.highlight })
			vim.api.nvim_set_hl(0, "BlinkCmpDocSeparator", { bg = colors.line, fg = colors.highlight })

			vim.api.nvim_set_hl(0, "BlinkCmpItemKindCopilot", { fg = colors.green })
			vim.api.nvim_set_hl(0, "BlinkCmpKindRipgrep", { fg = colors.pink })
			vim.api.nvim_set_hl(0, "BlinkCmpItemKindEmoji", { fg = colors.orange })
			vim.api.nvim_set_hl(0, "BlinkCmpItemKindNerdFonts", { fg = colors.cyan })

			koda.setup({
				transparent = false,
				theme = {
					dark = "dark",
					light = "light",
				},
				auto = true,
				cache = true,
				styles = {
					functions = { bold = true },
					keywords = {},
					comments = {},
					strings = {},
					constants = {},
				},
				colors = {
					-- func = "#4078F2",
					-- keyword = "#A627A4",
				},
				on_highlights = function(hl, c)
					-- hl.LineNr = { fg = c.info } -- change a specific highlight to use a different palette color
					-- hl.Comment = { fg = c.emphasis, italic = true } -- modify a syntax group (add bold, italic, etc)
					-- hl.RainbowDelimiterRed = { fg = "#fb2b2b" } -- add a custom highlight group for another plugin
				end,
			})
			vim.cmd("colorscheme koda-dark")
		end,
	},
	{
		"nvim-lualine/lualine.nvim",
		config = function()
			local koda = require("koda")
			local colors = koda.get_palette("dark")

			local hide_in_width = function()
				return vim.fn.winwidth(0) > 80
			end

			local icons = require("config.icons")

			local branch = {
				"branch",
				icon = { icons.git.Branch, align = "left" },
				use_mode_colors = false,
				color = function()
					return { bg = colors.line, fg = colors.fg, gui = "bold" }
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
					return { bg = colors.line, fg = colors.fg }
				end,
			}

			local filename = {
				"filename",
				icons_enabled = true,
				symbols = {
					modified = "  ",
					readonly = "  ",
					unnamed = "  ",
					newfile = "  ",
				},
				cond = hide_in_width,
				path = 4,
				shorting_target = 10,
				use_color_mode = true,
				color = function()
					return { bg = colors.line, fg = colors.fg }
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
					return { bg = colors.line, fg = colors.fg }
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
