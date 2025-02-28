-- luacheck: globals vim
-- luacheck: ignore 631

return {
  "brneor/hop.nvim",
  version = "*",
  event = "BufRead",
  config = function()
    require("hop").setup {
      keys = "tnplvmdhsefucwyxriao",
      multi_windows = false,
    }
    vim.api.nvim_set_keymap(
      "",
      "f",
      "<cmd>:lua require'hop'.hint_char1({direction = require'hop.hint'.HintDirection.AFTER_CURSOR,current_line_only = false})<cr>",
      { silent = true }
    )
    vim.api.nvim_set_keymap(
      "",
      "F",
      "<cmd>:lua require'hop'.hint_char1({direction = require'hop.hint'.HintDirection.BEFORE_CURSOR,current_line_only = false})<cr>",
      { silent = true }
    )
    vim.api.nvim_set_keymap("", "<C-w>", "<cmd>HopWordCurrentLineAC<cr>", { silent = true })
    vim.api.nvim_set_keymap("", "<C-b>", "<cmd>HopWordCurrentLineBC<cr>", { silent = true })
    vim.api.nvim_set_keymap(
      "",
      "t",
      "<cmd>:lua require'hop'.hint_char1({direction = require'hop.hint'.HintDirection.AFTER_CURSOR,current_line_only = false,hint_offset = -1})<cr>",
      { silent = true }
    )
    vim.api.nvim_set_keymap(
      "",
      "T",
      "<cmd>:lua require'hop'.hint_char1({direction = require'hop.hint'.HintDirection.BEFORE_CURSOR,current_line_only = false,hint_offset = 1})<cr>",
      { silent = true }
    )
  end,
}
