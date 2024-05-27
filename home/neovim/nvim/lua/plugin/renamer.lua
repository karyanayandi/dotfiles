return {
  "filipdutescu/renamer.nvim",
  config = function()
    vim.api.nvim_set_keymap(
      "i",
      "<F2>",
      '<cmd>lua require("renamer").rename({empty = true})<cr>',
      { noremap = true, silent = true }
    )
    vim.api.nvim_set_keymap(
      "n",
      "<F2>",
      '<cmd>lua require("renamer").rename({empty = true})<cr>',
      { noremap = true, silent = true }
    )
    local mappings_utils = require "renamer.mappings.utils"

    require("renamer").setup {
      title = "Rename",
      padding = {
        top = 0,
        left = 0,
        bottom = 0,
        right = 0,
      },
      border = true,
      border_chars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
      show_refs = true,
      mappings = {
        ["<c-i>"] = mappings_utils.set_cursor_to_start,
        ["<c-a>"] = mappings_utils.set_cursor_to_end,
        ["<c-e>"] = mappings_utils.set_cursor_to_word_end,
        ["<c-b>"] = mappings_utils.set_cursor_to_word_start,
        ["<c-c>"] = mappings_utils.clear_line,
        ["<c-u>"] = mappings_utils.undo,
        ["<c-r>"] = mappings_utils.redo,
      },
    }
  end,
}
