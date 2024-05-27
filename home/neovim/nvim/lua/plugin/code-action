return {
  "nvimtools/none-ls.nvim",
  event = "BufReadPre",
  config = function()
    local null_ls = require "null-ls"
    local code_actions = null_ls.builtins.code_actions

    require("null-ls").setup {
      debug = true,
      debounce = 150,
      sources = {
        code_actions.eslint_d,
        code_actions.gitsigns,
        code_actions.shellcheck,
        code_actions.refactoring,
      },
    }
  end,
}
