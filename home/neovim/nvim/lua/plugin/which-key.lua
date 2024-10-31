return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  config = function()
    local setup = {
      preset = "helix",
      plugins = {
        marks = true,
        registers = true,
        spelling = {
          enabled = true,
          suggestions = 20,
        },
        presets = {
          operators = false,
          motions = false,
          text_objects = false,
          windows = true,
          nav = true,
          z = true,
          g = true,
        },
      },
      icons = {
        breadcrumb = "»",
        separator = "➜",
        group = "+",
      },
      win = {
        border = "rounded",
        position = "bottom",
        no_overlap = false,
        margin = { 1, 0, 1, 0 },
        padding = { 2, 2, 2, 2 },
        title = false,
        title_pos = "center",
        zindex = 1000,
      },
      layout = {
        height = { min = 4, max = 25 },
        width = { min = 20, max = 50 },
        spacing = 3,
        align = "center",
      },
      hidden = { "<silent>", "<cmd>", "<Cmd>", "<CR>", "call", "lua", "^:", "^ " },
      show_help = false,
    }

    local opts = {
      mode = "n",
      prefix = "<leader>",
      buffer = nil,
      silent = true,
      noremap = true,
      nowait = true,
    }

    local mappings = {
      {
        "<leader>a",
        "<cmd>Alpha</cmd>",
        desc = "Alpha",
      },
      {
        "<leader>b",
        "<cmd>lua require('telescope.builtin').buffers(require('telescope.themes').get_ivy{previewer = false, initial_mode='normal'})<cr>",
        desc = "Buffer",
      },
      {
        "<leader>c",
        "<cmd>:Bdelete<cr>",
        desc = "Close",
      },
      {
        "<leader>e",
        "<cmd>NvimTreeToggle<cr>",
        desc = "Explorer",
      },
      {
        "<leader>w",
        "<cmd>w<CR>",
        desc = "Write",
      },
      {
        "<leader>h",
        "<cmd>nohlsearch<CR>",
        desc = "No HL",
      },
      {
        "<leader>q",
        "<cmd>lua require('config.functions').smart_quit()<CR>",
        desc = "Quit",
      },
      {
        "<leader>t",
        "<cmd>lua _FLOAT_TERM()<cr>",
        "Terminal",
      },
      {
        "<leader>/",
        '<cmd>lua require("Comment.api").toggle.linewise.current()<CR>',
        desc = "Comment",
      },
      {
        "<leader>p",
        "<cmd>lua require('telescope').extensions.projects.projects()<cr>",
        desc = "Projects",
      },
      z = {
        name = "Lazy",
        i = { "<cmd>Lazy<cr>", "Install" },
        l = { "<cmd>Lazy log<cr>", "Log" },
        s = { "<cmd>Lazy sync<cr>", "Sync" },
        c = { "<cmd>Lazy check<cr>", "check" },
        x = { "<cmd>Lazy clean<cr>", "Clean" },
        u = { "<cmd>Lazy update<cr>", "Update" },
        d = { "<cmd>Lazy debug<cr>", "Debug" },
        p = { "<cmd>Lazy profile<cr>", "Profile" },
        r = { "<cmd>Lazy restore<cr>", "Restore" },
      },
      o = {
        name = "Options",
        w = { '<cmd>lua require("config.functions").toggle_option("wrap")<cr>', "Wrap" },
        r = { '<cmd>lua require("config.functions").toggle_option("relativenumber")<cr>', "Relative" },
        l = { '<cmd>lua require("config.functions").toggle_option("cursorline")<cr>', "Cursorline" },
        S = { '<cmd>lua require("config.functions").toggle_option("spell")<cr>', "Spell" },
        s = { "<cmd>sort<cr>", "Short" },
        t = { '<cmd>lua require("config.functions").toggle_tabline()<cr>', "Tabline" },
        c = { "<cmd>Telescope colorscheme<cr>", "Colorscheme" },
      },
      r = {
        name = "Replace",
        r = { "<cmd>lua require('spectre').open()<cr>", "Replace" },
        f = { "<cmd>lua require('spectre').open_file_search()<cr>", "Replace in This Buffer" },
        w = { "<cmd>lua require('spectre').open_visual({select_word=true})<cr>", "Replace Selected Word" },
      },
      R = {
        name = "Refactoring",
        r = { "<cmd>lua require('refactoring').select_refactor()<cr>", "Refactor" },
        b = { "<cmd>lua require('refactoring').refactor('Extract Block')<cr>", "Extract Block" },
        B = { "<cmd>lua require('refactoring').refactor('Extract Block To File')<cr>", "Extract Block To File" },
        f = { "<cmd>lua require('refactoring').refactor('Extract Function')<cr>", "Extact Function" },
        F = { "<cmd>lua require('refactoring').refactor('Extract Function To File')<cr>", "Extact Function To File" },
        i = { "<cmd>lua require('refactoring').refactor('Inline Variable')<cr>", "Inline Variable" },
      },
      f = {
        name = "Find",
        b = {
          "<cmd>lua require('telescope.builtin').buffers(require('telescope.themes').get_ivy{previewer = false, initial_mode='normal'})<cr>",
          "Buffer",
        },
        B = {
          "<cmd>lua require('telescope.builtin').git_branches(require('telescope.themes').get_ivy{previewer = false, initial_mode='normal'})<cr>",
          "Checkout branch",
        },
        f = {
          "<cmd>lua require('telescope.builtin').find_files(require('telescope.themes').get_ivy{previewer = false})<cr>",
          "Find files",
        },
        t = { "<cmd>Telescope live_grep theme=ivy<cr>", "Find Text" },
        T = { "<cmd>TodoTelescope theme=ivy<cr>", "Find Todo" },
        -- TODO: Fix treesitter error when access telecope help_tags
        h = { "<cmd>Telescope help_tags<cr>", "Help" },
        i = { "<cmd>lua require('telescope').extensions.media_files.media_files()<cr>", "Media" },
        l = { "<cmd>Telescope resume<cr>", "Last Search" },
        M = { "<cmd>Telescope man_pages<cr>", "Man Pages" },
        r = { "<cmd>Telescope oldfiles<cr>", "Recent File" },
        R = { "<cmd>Telescope registers<cr>", "Registers" },
        k = { "<cmd>Telescope keymaps<cr>", "Keymaps" },
        C = { "<cmd>Telescope commands<cr>", "Commands" },
        u = { "<cmd>lua require('undotree').toggle()<cr>", "Undotree" },
      },
      g = {
        name = "Git",
        g = { "<cmd>lua _LAZYGIT_TOGGLE()<CR>", "Lazygit" },
        j = { "<cmd>lua require 'gitsigns'.next_hunk()<cr>", "Next Hunk" },
        k = { "<cmd>lua require 'gitsigns'.prev_hunk()<cr>", "Prev Hunk" },
        l = { "<cmd>lua require 'gitsigns'.toggle_current_line_blame()<cr>", "Blame" },
        p = { "<cmd>lua require 'gitsigns'.preview_hunk()<cr>", "Preview Hunk" },
        r = { "<cmd>lua require 'gitsigns'.reset_hunk()<cr>", "Reset Hunk" },
        R = { "<cmd>lua require 'gitsigns'.reset_buffer()<cr>", "Reset Buffer" },
        s = { "<cmd>lua require 'gitsigns'.stage_hunk()<cr>", "Stage Hunk" },
        u = {
          "<cmd>lua require 'gitsigns'.undo_stage_hunk()<cr>",
          "Undo Stage Hunk",
        },
        o = { "<cmd>Telescope git_status<cr>", "Open changed file" },
        b = { "<cmd>Telescope git_branches<cr>", "Checkout branch" },
        c = { "<cmd>Telescope git_commits<cr>", "Checkout commit" },
        d = { "<cmd>lua require 'gitsigns'.diffthis()<cr>", "Diffview" },
      },
      l = {
        name = "LSP",
        a = { "<cmd>lua require('actions-preview').code_actions()<cr>", "Code Action" },
        A = { "<cmd>lua vim.lsp.codelens.run()<cr>", "CodeLens Action" },
        d = { "<cmd>Trouble diagnostics toggle win.position=bottom<cr>", "Diagnostics" },
        f = { "<cmd>AutoFormatOnSaveToggle<cr>", "Toggle autoformat-on-save" },
        i = { "<cmd>LspInfo<cr>", "Info" },
        h = { "<cmd>ToggleInlayHint<cr>", "Toggle Inlay Hint" },
        H = { "<cmd>lua require('illuminate').toggle()<cr>", "Toggle Doc HL" },
        I = { "<cmd>LspInstall<cr>", "Installer Info" },
        j = {
          "<cmd>lua vim.diagnostic.goto_next({buffer=0})<CR>",
          "Next Diagnostic",
        },
        k = {
          "<cmd>lua vim.diagnostic.goto_prev({buffer=0})<cr>",
          "Prev Diagnostic",
        },
        m = { "<cmd>Mason<cr>", "Mason Info" },
        q = { "<cmd>Trouble qflist toggle<cr>", "Quickfix" },
        r = { "<cmd>lua vim.lsp.buf.rename()<cr>", "Rename" },
        R = { "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", "References" },
        s = { "<cmd>Telescope lsp_document_symbols<cr>", "Document Symbols" },
        S = {
          "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>",
          "Workspace Symbols",
        },
        t = { '<cmd>lua require("config.functions").toggle_diagnostics()<cr>', "Toggle Diagnostics" },
        T = { "<cmd>TodoTrouble keywords=TODO,FIX,FIXME<cr>", "Todo Diagnostics" },
        u = { "<cmd>LuaSnipUnlinkCurrent<cr>", "Unlink Snippet" },
      },
      t = {
        name = "Test",
        t = { "<cmd>TestNearest<cr>", "Nearest" },
        f = { "<cmd>TestFile<cr>", "File" },
        a = { "<cmd>TestSuite<cr>", "All" },
        l = { "<cmd>TestLast<cr>", "Last" },
        v = { "<cmd>TestVisit<cr>", "Visit" },
      },
      w = {
        name = "Workspaces",
        a = { "<cmd>WorkspacesAdd<cr>", "Add" },
        A = { "<cmd>WorkspacesAddDir<cr>", "Add Dir" },
        d = { "<cmd>WorkspacesRemove<cr>", "Remove" },
        D = { "<cmd>WorkspacesRemoveDir<cr>", "Remove Dir" },
        l = { "<cmd>WorkspacesList<cr>", "List" },
        o = { "<cmd>WorkspacesOpen<cr>", "Open" },
        r = { "<cmd>WorkspacesRename<cr>", "Rename" },
        s = { "<cmd>WorkspacesSyncDirs<cr>", "Sync" },
      },
    }

    local vopts = {
      mode = "v",
      prefix = "<leader>",
      buffer = nil,
      silent = true,
      noremap = true,
      nowait = true,
    }

    local vmappings = {
      ["/"] = { '<ESC><CMD>lua require("Comment.api").toggle.linewise(vim.fn.visualmode())<CR>', "Comment" },
      s = { ":'<,'>sort<CR>", "Sort selected lines" },
      c = { "<ESC>:'<,'>CarbonNow<CR>", "Capture Image" },
    }

    require("which-key").setup(setup)
    require("which-key").add(mappings, opts)
    require("which-key").add(vmappings, vopts)
  end,
}
