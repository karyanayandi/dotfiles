-- luacheck: globals vim

return {
  "smartpde/neoscopes",
  dependencies = { "nvim-telescope/telescope.nvim" },
  config = function()
    local scopes = require "neoscopes"

    scopes.setup {
      diff_ancestors_for_scopes = { "main", "origin/main" },
    }

    _G.find_files = function()
      require("telescope.builtin").find_files {
        search_dirs = scopes.get_current_dirs(),
        theme = "ivy",
      }
    end

    _G.live_grep = function()
      require("telescope.builtin").live_grep {
        search_dirs = scopes.get_current_dirs(),
        theme = "ivy",
      }
    end

    vim.api.nvim_set_keymap("n", ";f", ":lua find_files()<CR>", { noremap = true })
    vim.api.nvim_set_keymap("n", ";t", ":lua live_grep()<CR>", { noremap = true })
  end,
}
