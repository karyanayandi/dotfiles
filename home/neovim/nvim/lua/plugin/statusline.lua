-- luacheck: globals vim

return {
  "echasnovski/mini.statusline",
  version = false,
  config = function()
    local MiniStatusline = require "mini.statusline"
    local blocked_filetypes = {
      "snacks_terminal",
      "snacks_dashboard",
      "copilot-chat",
      "copilot-diff",
      "copilot-overlay",
    }

    local content_active = function()
      if blocked_filetypes[vim.bo.filetype] then
        return ""
      end

      local mode, mode_hl = MiniStatusline.section_mode { trunc_width = 120 }
      local git = MiniStatusline.section_git { trunc_width = 75 }
      local diff = MiniStatusline.section_diff { trunc_width = 75 }
      local diagnostics = MiniStatusline.section_diagnostics { trunc_width = 120 }
      local lsp = MiniStatusline.section_lsp { trunc_width = 75 }
      local filename = MiniStatusline.section_filename { trunc_width = 75 }
      local fileinfo = MiniStatusline.section_fileinfo { trunc_width = 120 }
      local location = MiniStatusline.section_location { trunc_width = 75 }
      -- local search = MiniStatusline.section_searchcount { trunc_width = 75 }

      return MiniStatusline.combine_groups {
        { hl = mode_hl, strings = { mode } },
        { hl = "MiniStatuslineDevinfo", strings = { git, diff, diagnostics, lsp } },
        "%<", -- Mark general truncate point
        { hl = "MiniStatuslineFilename", strings = { filename } },
        "%=", -- End left alignment
        { hl = "MiniStatuslineFileinfo", strings = { fileinfo } },
        { hl = mode_hl, strings = { location } },
      }
    end

    MiniStatusline.setup {
      content = {
        active = content_active,
        inactive = nil,
      },
      use_icons = true,
      set_vim_settings = true,
    }
  end,
}
