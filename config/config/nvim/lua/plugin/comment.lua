-- luacheck: globals vim

return {
  "numToStr/Comment.nvim",
  lazy = false,
  dependencies = {
    {
      "JoosepAlviste/nvim-ts-context-commentstring",
      event = "VeryLazy",
    },
  },

  config = function()
    vim.keymap.set("n", "<leader>/", "<Plug>(comment_toggle_linewise_current)", { desc = "Comment" })
    vim.keymap.set("x", "<leader>/", "<Plug>(comment_toggle_linewise_visual)", { desc = "Comment" })
    vim.keymap.set("v", "<leader>/", "<Plug>(comment_toggle_linewise_visual)", { desc = "Comment" })
    vim.keymap.set("n", "<C-/>", "<Plug>(comment_toggle_linewise_current)", { desc = "Comment" })
    vim.keymap.set("x", "<C-/>", "<Plug>(comment_toggle_linewise_visual)", { desc = "Comment" })
    vim.keymap.set("v", "<C-/>", "<Plug>(comment_toggle_linewise_visual)", { desc = "Comment" })
    vim.keymap.set("n", "<A-/>", "<Plug>(comment_toggle_linewise_current)", { desc = "Comment" })
    vim.keymap.set("x", "<A-/>", "<Plug>(comment_toggle_linewise_visual)", { desc = "Comment" })
    vim.keymap.set("v", "<A-/>", "<Plug>(comment_toggle_linewise_visual)", { desc = "Comment" })

    vim.g.skip_ts_context_commentstring_module = true
    ---@diagnostic disable: missing-fields
    require("ts_context_commentstring").setup {
      enable_autocmd = false,
    }

    require("Comment").setup {
      padding = true,
      sticky = true,
      toggler = {
        line = "gcc",
        block = "gbc",
      },
      opleader = {
        line = "gc",
        block = "gb",
      },
      extra = {
        above = "gcO",
        below = "gco",
        eol = "gcA",
      },
      mappings = {
        basic = true,
        extra = true,
      },
      pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
    }
  end,
}
