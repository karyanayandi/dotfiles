-- luacheck: globals vim
-- luacheck: ignore 631

return {
  "smoka7/hop.nvim",
  version = "*",
  event = "VeryLazy",
  opts = {
    keys = "etovxqpdygfblzhckisuran",
  },
  config = function()
    local opts = { noremap = true, silent = true }
    local keymap = vim.api.nvim_set_keymap

    keymap(
      "o",
      "f",
      ":lua require'hop'.hint_char1({ direction = require'hop.hint'.HintDirection.AFTER_CURSOR, current_line_only = true })<CR>",
      opts
    )
    keymap(
      "o",
      "F",
      ":lua require'hop'.hint_char1({ direction = require'hop.hint'.HintDirection.BEFORE_CURSOR, current_line_only = true })<CR>",
      opts
    )
    keymap(
      "o",
      "t",
      ":lua require'hop'.hint_char1({ direction = require'hop.hint'.HintDirection.AFTER_CURSOR, current_line_only = true, hint_offset = -1 })<CR>",
      opts
    )
    keymap(
      "o",
      "T",
      ":lua require'hop'.hint_char1({ direction = require'hop.hint'.HintDirection.BEFORE_CURSOR, current_line_only = true, hint_offset = 1 })<CR>",
      opts
    )

    keymap(
      "n",
      "f",
      ":lua require'hop'.hint_char1({ direction = require'hop.hint'.HintDirection.AFTER_CURSOR, current_line_only = false })<CR>",
      opts
    )
    keymap(
      "n",
      "F",
      ":lua require'hop'.hint_char1({ direction = require'hop.hint'.HintDirection.BEFORE_CURSOR, current_line_only = false })<CR>",
      opts
    )
    keymap(
      "n",
      "t",
      ":lua require'hop'.hint_char1({ direction = require'hop.hint'.HintDirection.AFTER_CURSOR, current_line_only = true, hint_offset = -1 })<CR>",
      opts
    )
    keymap(
      "n",
      "T",
      ":lua require'hop'.hint_char1({ direction = require'hop.hint'.HintDirection.BEFORE_CURSOR, current_line_only = true, hint_offset = 1 })<CR>",
      opts
    )
  end,
}
