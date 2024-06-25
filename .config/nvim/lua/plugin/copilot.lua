return {
  "zbirenbaum/copilot.lua",
  event = { "InsertEnter", "LspAttach" },
  cmd = "Copilot",
  build = ":Copilot auth",
  config = function()
    require("copilot").setup {
      panel = {
        enabled = false,
      },
      suggestion = {
        enabled = false,
      },
      filetypes = {
        yaml = false,
        markdown = false,
        help = false,
        gitcommit = false,
        gitrebase = false,
        hgcommit = false,
        svn = false,
        cvs = false,
        ["."] = false,
      },
      copilot_node_command = "node",
      server_opts_overrides = {},
    }
  end,
}
