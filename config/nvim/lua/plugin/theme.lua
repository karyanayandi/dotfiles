
return {
  {
    "RRethy/base16-nvim",
    priority = 10,
    config = function()
      vim.cmd "colorscheme base16-gruvbox-dark-hard"
      local hl = vim.api.nvim_set_hl
      -- base16-nvim doesn't theme neotest; wire it to existing groups
      -- https://github.com/nvim-neotest/neotest
      hl(0, "NeotestPassed", { link = "DiagnosticOk" })
      hl(0, "NeotestFailed", { link = "DiagnosticError" })
      hl(0, "NeotestRunning", { link = "DiagnosticWarn" })
      hl(0, "NeotestSkipped", { link = "DiagnosticInfo" })
      hl(0, "NeotestUnknown", { link = "Comment" })
      hl(0, "NeotestFocused", { link = "Title", bold = true })
      hl(0, "NeotestMarked", { link = "MoreMsg" })
      hl(0, "NeotestFile", { link = "Directory" })
      hl(0, "NeotestDir", { link = "Directory" })
      hl(0, "NeotestNamespace", { link = "Keyword" })
      hl(0, "NeotestAdapterName", { link = "Type" })
      hl(0, "NeotestTest", { link = "Normal" })
      hl(0, "NeotestIndent", { link = "Normal" })
      hl(0, "NeotestExpandMarker", { link = "Normal" })
    end,
  },
}
