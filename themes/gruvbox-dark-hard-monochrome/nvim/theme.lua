-- luacheck: globals vim

return {
	{
		"RRethy/base16-nvim",
		priority = 10,
		config = function()
			require("base16-colorscheme").setup({
				base00 = "#1d2021",
				base01 = "#32302f",
				base02 = "#3c3836",
				base03 = "#504945",
				base04 = "#bdae93",
				base05 = "#d5c4a1",
				base06 = "#ebdbb2",
				base07 = "#fbf1c7",
				base08 = "#928374",
				base09 = "#a89984",
				base0A = "#bdae93",
				base0B = "#928374",
				base0C = "#a89984",
				base0D = "#a89984",
				base0E = "#bdae93",
				base0F = "#665c54",
			})
			vim.api.nvim_set_hl(0, "PmenuMatch", { fg = "#458588", bold = true })
			vim.api.nvim_set_hl(0, "Question", { fg = "#458588", bold = true })
			vim.api.nvim_set_hl(0, "QuickFixLine", { fg = "#458588", bold = true })
			vim.api.nvim_set_hl(0, "DiagnosticError", { fg = "#fb4934", bold = true })
			vim.api.nvim_set_hl(0, "DiagnosticWarn", { fg = "#fe8019", bold = true })
			vim.api.nvim_set_hl(0, "DiagnosticInfo", { fg = "#458588", bold = true })
			vim.api.nvim_set_hl(0, "DiagnosticHint", { fg = "#b8bb26", bold = true })
			vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", { fg = "#fb4934", bold = true })
			vim.api.nvim_set_hl(0, "DiagnosticUnderlineWarn", { fg = "#fe8019", bold = true })
			vim.api.nvim_set_hl(0, "DiagnosticUnderlineInfo", { fg = "#458588", bold = true })
			vim.api.nvim_set_hl(0, "DiagnosticUnderlineHint", { fg = "#b8bb26", bold = true })

			vim.api.nvim_set_hl(0, "GitSignsAdd", { fg = "#b8bb26" })
			vim.api.nvim_set_hl(0, "GitSignsChange", { fg = "#458588" })
			vim.api.nvim_set_hl(0, "GitSignsDelete", { fg = "#fb4934" })
			vim.api.nvim_set_hl(0, "GitSignsStagedAdd", { fg = "#b8bb26" })
			vim.api.nvim_set_hl(0, "GitSignsStagedChange", { fg = "#458588" })
			vim.api.nvim_set_hl(0, "GitSignsStagedDelete", { fg = "#fb4934" })

			local constant = "#B16286"
			vim.api.nvim_set_hl(0, "Constant", { fg = constant, bold = true })
			vim.api.nvim_set_hl(0, "Number", { fg = constant, bold = true })
			vim.api.nvim_set_hl(0, "Boolean", { fg = constant, bold = true })
			vim.api.nvim_set_hl(0, "Float", { fg = constant, bold = true })
			vim.api.nvim_set_hl(0, "@constant", { fg = constant, bold = true })
			vim.api.nvim_set_hl(0, "@constant.builtin", { fg = constant, bold = true })
			vim.api.nvim_set_hl(0, "@constant.macro", { fg = constant, bold = true })
			vim.api.nvim_set_hl(0, "@boolean", { fg = constant, bold = true })
			vim.api.nvim_set_hl(0, "@number", { fg = constant, bold = true })
			vim.api.nvim_set_hl(0, "@number.float", { fg = constant, bold = true })
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
						"fzf",
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
					lualine_x = {
						-- {
						-- 	"lsp_status",
						-- 	icon = "",
						-- 	symbols = {
						-- 		spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
						-- 		done = "✓",
						-- 		separator = " ",
						-- 	},
						-- 	ignore_lsp = { "copilot", "emmet_ls" },
						-- 	show_name = true,
						-- },
					},
					lualine_y = { diagnostics },
					-- lualine_z = { filetype, "location" },
					lualine_z = { "location" },
				},
				extensions = {},
			})
		end,
	},
}
