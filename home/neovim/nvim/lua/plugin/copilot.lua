-- luacheck: globals vim

return {
  "zbirenbaum/copilot.lua",
  event = { "InsertEnter", "LspAttach" },
  cmd = "Copilot",
  build = ":Copilot auth",
  config = function()
    require("copilot").setup {
      panel = {
        enabled = false,
        keymap = {
          jump_next = "<c-j>",
          jump_prev = "<c-k>",
          accept = "<c-l>",
          refresh = "r",
          open = "<M-CR>",
        },
      },
      suggestion = {
        enabled = false,
        auto_trigger = true,
        keymap = {
          accept = "<c-l>",
          next = "<c-j>",
          prev = "<c-k>",
          dismiss = "<c-h>",
        },
      },
      filetypes = {
        yaml = true,
        markdown = true,
        help = false,
        gitcommit = false,
        gitrebase = false,
        cvs = false,
        ["."] = false,
      },
      copilot_node_command = "node",
      server_opts_overrides = {},
    }

    local opts = { noremap = true, silent = true }
    vim.api.nvim_set_keymap("n", "<c-c>", ":lua require('copilot.suggestion').toggle_auto_trigger()<CR>", opts)
  end,
}
