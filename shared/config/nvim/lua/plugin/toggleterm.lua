-- luacheck: globals vim

return {
  "akinsho/toggleterm.nvim",
  event = "VeryLazy",
  config = function()
    require("toggleterm").setup {
      size = 20,
      open_mapping = [[<m-0>]],
      hide_numbers = true,
      shade_filetypes = {},
      shade_terminals = true,
      shading_factor = 2,
      start_in_insert = true,
      insert_mappings = true,
      persist_size = true,
      direction = "float",
      close_on_exit = true,
      shell = vim.o.shell,
      float_opts = {
        border = "curved",
        winblend = 0,
        highlights = {
          border = "Normal",
          background = "Normal",
        },
      },
    }

    ---@diagnostic disable-next-line: duplicate-set-field
    function _G.set_terminal_keymaps()
      local opts = { noremap = true }
      vim.api.nvim_buf_set_keymap(0, "t", "<C-h>", [[<C-\><C-n><C-W>h]], opts)
      vim.api.nvim_buf_set_keymap(0, "t", "<C-j>", [[<C-\><C-n><C-W>j]], opts)
      vim.api.nvim_buf_set_keymap(0, "t", "<C-k>", [[<C-\><C-n><C-W>k]], opts)
      vim.api.nvim_buf_set_keymap(0, "t", "<C-l>", [[<C-\><C-n><C-W>l]], opts)
    end

    vim.cmd "autocmd! TermOpen term://* lua set_terminal_keymaps()"

    local Terminal = require("toggleterm.terminal").Terminal

    local lazygit = Terminal:new {
      cmd = "lazygit",
      hidden = true,
      direction = "float",
      on_open = function(_)
        vim.cmd "startinsert!"
        vim.cmd "set laststatus=0"
      end,
      on_close = function(_)
        vim.cmd "set laststatus=3"
      end,
      count = 100,
    }

    function _LAZYGIT_TOGGLE()
      lazygit:toggle()
    end

    local lazygitlog = Terminal:new {
      cmd = "lazygit log",
      hidden = true,
      direction = "float",
      on_open = function(_)
        vim.cmd "startinsert!"
        vim.cmd "set laststatus=0"
      end,
      on_close = function(_)
        vim.cmd "set laststatus=3"
      end,
      count = 100,
    }

    function _LAZYGIT_LOG_TOGGLE()
      lazygitlog:toggle()
    end

    local opencode = Terminal:new {
      cmd = "opencode",
      hidden = true,
      direction = "float",
      float_opts = {
        border = "single",
      },
      on_open = function(_)
        vim.cmd "startinsert!"
        vim.cmd "set laststatus=0"
      end,
      on_close = function(_)
        vim.cmd "set laststatus=3"
      end,
      count = 100,
    }

    function _OPENCODE_TOGGLE()
      opencode:toggle()
    end

    local float_term = Terminal:new {
      direction = "float",
      on_open = function(term)
        vim.cmd "startinsert!"
        vim.api.nvim_buf_set_keymap(
          term.bufnr,
          "n",
          "<C-t>",
          "<cmd>1ToggleTerm direction=float<cr>",
          { noremap = true, silent = true }
        )
        vim.api.nvim_buf_set_keymap(
          term.bufnr,
          "t",
          "<C-t>",
          "<cmd>1ToggleTerm direction=float<cr>",
          { noremap = true, silent = true }
        )
        vim.api.nvim_buf_set_keymap(
          term.bufnr,
          "i",
          "<C-t>",
          "<cmd>1ToggleTerm direction=float<cr>",
          { noremap = true, silent = true }
        )
      end,
      count = 1,
    }

    function _FLOAT_TERM()
      float_term:toggle()
    end

    vim.api.nvim_set_keymap("n", "<C-t>", "<cmd>lua _FLOAT_TERM()<CR>", { noremap = true, silent = true })
    vim.api.nvim_set_keymap("i", "<C-t>", "<cmd>lua _FLOAT_TERM()<CR>", { noremap = true, silent = true })
    vim.api.nvim_set_keymap("n", ";o", "<cmd>lua _OPENCODE_TOGGLE()<CR>", { noremap = true, silent = true })
    vim.api.nvim_set_keymap("i", ";o", "<cmd>lua _OPENCODE_TOGGLE()<CR>", { noremap = true, silent = true })
  end,
}
