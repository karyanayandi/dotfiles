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
      {
        "<leader>zi",
        "<cmd>Lazy<cr>",
        desc = "Install",
      },
      {
        "<leader>zi",
        "<cmd>Lazy<cr>",
        desc = "Install",
      },
      {
        "<leader>zl",
        "<cmd>Lazy log<cr>",
        desc = "Log",
      },
      {
        "<leader>zs",
        "<cmd>Lazy sync<cr>",
        desc = "Sync",
      },
      {
        "<leader>zc",
        "<cmd>Lazy check<cr>",
        desc = "Check",
      },
      {
        "<leader>zx",
        "<cmd>Lazy clean<cr>",
        desc = "Clean",
      },
      {
        "<leader>zu",
        "<cmd>Lazy update<cr>",
        desc = "Update",
      },
      {
        "<leader>zd",
        "<cmd>Lazy debug<cr>",
        desc = "Debug",
      },
      {
        "<leader>zp",
        "<cmd>Lazy profile<cr>",
        desc = "Profile",
      },
      {
        "<leader>zr",
        "<cmd>Lazy restore<cr>",
        desc = "Restore",
      },

      {
        "<leader>ow",
        '<cmd>lua require("config.functions").toggle_option("wrap")<cr>',
        desc = "Wrap",
      },
      {
        "<leader>or",
        '<cmd>lua require("config.functions").toggle_option("relativenumber")<cr>',
        desc = "Relative",
      },
      {
        "<leader>ol",
        '<cmd>lua require("config.functions").toggle_option("cursorline")<cr>',
        desc = "Cursorline",
      },
      {
        "<leader>oS",
        '<cmd>lua require("config.functions").toggle_option("spell")<cr>',
        desc = "Spell",
      },
      {
        "<leader>os",
        "<cmd>sort<cr>",
        desc = "Sort",
      },
      {
        "<leader>ot",
        '<cmd>lua require("config.functions").toggle_tabline()<cr>',
        desc = "Tabline",
      },
      {
        "<leader>oc",
        "<cmd>Telescope colorscheme<cr>",
        desc = "Colorscheme",
      },

      {
        "<leader>rr",
        "<cmd>lua require('spectre').open()<cr>",
        desc = "Replace",
      },
      {
        "<leader>rf",
        "<cmd>lua require('spectre').open_file_search()<cr>",
        desc = "Replace in Buffer",
      },
      {
        "<leader>rw",
        "<cmd>lua require('spectre').open_visual({select_word=true})<cr>",
        desc = "Replace Selected Word",
      },

      {
        "<leader>Rr",
        "<cmd>lua require('refactoring').select_refactor()<cr>",
        desc = "Refactor",
      },
      {
        "<leader>Rb",
        "<cmd>lua require('refactoring').refactor('Extract Block')<cr>",
        desc = "Extract Block",
      },
      {
        "<leader>RB",
        "<cmd>lua require('refactoring').refactor('Extract Block To File')<cr>",
        desc = "Extract Block To File",
      },
      {
        "<leader>Rf",
        "<cmd>lua require('refactoring').refactor('Extract Function')<cr>",
        desc = "Extract Function",
      },
      {
        "<leader>RF",
        "<cmd>lua require('refactoring').refactor('Extract Function To File')<cr>",
        desc = "Extract Function To File",
      },
      {
        "<leader>Ri",
        "<cmd>lua require('refactoring').refactor('Inline Variable')<cr>",
        desc = "Inline Variable",
      },

      {
        "<leader>fb",
        "<cmd>lua require('telescope.builtin').buffers(require('telescope.themes').get_ivy{previewer = false, initial_mode='normal'})<cr>",
        desc = "Buffer",
      },
      {
        "<leader>fB",
        "<cmd>lua require('telescope.builtin').git_branches(require('telescope.themes').get_ivy{previewer = false, initial_mode='normal'})<cr>",
        desc = "Checkout Branch",
      },
      {
        "<leader>ff",
        "<cmd>lua require('telescope.builtin').find_files(require('telescope.themes').get_ivy{previewer = false})<cr>",
        desc = "Find Files",
      },
      {
        "<leader>ft",
        "<cmd>Telescope live_grep theme=ivy<cr>",
        desc = "Find Text",
      },
      {
        "<leader>fT",
        "<cmd>TodoTelescope theme=ivy<cr>",
        desc = "Find Todo",
      },
      {
        "<leader>fh",
        "<cmd>Telescope help_tags<cr>",
        desc = "Help",
      },
      {
        "<leader>fi",
        "<cmd>lua require('telescope').extensions.media_files.media_files()<cr>",
        desc = "Media",
      },
      {
        "<leader>fl",
        "<cmd>Telescope resume<cr>",
        desc = "Last Search",
      },
      {
        "<leader>fM",
        "<cmd>Telescope man_pages<cr>",
        desc = "Man Pages",
      },
      {
        "<leader>fr",
        "<cmd>Telescope oldfiles<cr>",
        desc = "Recent File",
      },
      {
        "<leader>fR",
        "<cmd>Telescope registers<cr>",
        desc = "Registers",
      },
      {
        "<leader>fk",
        "<cmd>Telescope keymaps<cr>",
        desc = "Keymaps",
      },
      {
        "<leader>fC",
        "<cmd>Telescope commands<cr>",
        desc = "Commands",
      },
      {
        "<leader>fu",
        "<cmd>lua require('undotree').toggle()<cr>",
        desc = "Undotree",
      },

      {
        "<leader>gg",
        "<cmd>lua _LAZYGIT_TOGGLE()<CR>",
        desc = "Lazygit",
      },
      {
        "<leader>gj",
        "<cmd>lua require 'gitsigns'.next_hunk()<cr>",
        desc = "Next Hunk",
      },
      {
        "<leader>gk",
        "<cmd>lua require 'gitsigns'.prev_hunk()<cr>",
        desc = "Prev Hunk",
      },
      {
        "<leader>gl",
        "<cmd>lua require 'gitsigns'.toggle_current_line_blame()<cr>",
        desc = "Blame",
      },
      {
        "<leader>gp",
        "<cmd>lua require 'gitsigns'.preview_hunk()<cr>",
        desc = "Preview Hunk",
      },
      {
        "<leader>gr",
        "<cmd>lua require 'gitsigns'.reset_hunk()<cr>",
        desc = "Reset Hunk",
      },
      {
        "<leader>gR",
        "<cmd>lua require 'gitsigns'.reset_buffer()<cr>",
        desc = "Reset Buffer",
      },
      {
        "<leader>gs",
        "<cmd>lua require 'gitsigns'.stage_hunk()<cr>",
        desc = "Stage Hunk",
      },
      {
        "<leader>gu",
        "<cmd>lua require 'gitsigns'.undo_stage_hunk()<cr>",
        desc = "Undo Stage Hunk",
      },
      {
        "<leader>go",
        "<cmd>Telescope git_status<cr>",
        desc = "Open Changed File",
      },
      {
        "<leader>gb",
        "<cmd>Telescope git_branches<cr>",
        desc = "Checkout Branch",
      },
      {
        "<leader>gc",
        "<cmd>Telescope git_commits<cr>",
        desc = "Checkout Commit",
      },
      {
        "<leader>gd",
        "<cmd>lua require 'gitsigns'.diffthis()<cr>",
        desc = "Diffview",
      },
      { "<leader>a", "<cmd>lua require('actions-preview').code_actions()<cr>", desc = "Code Action" },
      { "<leader>A", "<cmd>lua vim.lsp.codelens.run()<cr>", desc = "CodeLens Action" },
      { "<leader>d", "<cmd>Trouble diagnostics toggle win.position=bottom<cr>", desc = "Diagnostics" },
      {
        "<leader>f",
        "<cmd>AutoFormatOnSaveToggle<cr>",
        desc = "Toggle autoformat-on-save",
      },
      { "<leader>i", "<cmd>LspInfo<cr>", desc = "Info" },
      { "<leader>h", "<cmd>ToggleInlayHint<cr>", desc = "Toggle Inlay Hint" },
      { "<leader>H", "<cmd>lua require('illuminate').toggle()<cr>", desc = "Toggle Doc HL" },
      { "<leader>I", "<cmd>LspInstall<cr>", desc = "Installer Info" },
      { "<leader>j", "<cmd>lua vim.diagnostic.goto_next({buffer=0})<cr>", desc = "Next Diagnostic" },
      { "<leader>k", "<cmd>lua vim.diagnostic.goto_prev({buffer=0})<cr>", desc = "Prev Diagnostic" },
      { "<leader>m", "<cmd>Mason<cr>", desc = "Mason Info" },
      { "<leader>q", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix" },
      { "<leader>r", "<cmd>lua vim.lsp.buf.rename()<cr>", desc = "Rename" },
      { "<leader>R", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "References" },
      { "<leader>s", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Document Symbols" },
      { "<leader>S", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", desc = "Workspace Symbols" },
      { "<leader>t", '<cmd>lua require("config.functions").toggle_diagnostics()<cr>', desc = "Toggle Diagnostics" },
      { "<leader>T", "<cmd>TodoTrouble keywords=TODO,FIX,FIXME<cr>", desc = "Todo Diagnostics" },
      { "<leader>u", "<cmd>LuaSnipUnlinkCurrent<cr>", desc = "Unlink Snippet" },
      { "<leader>tt", "<cmd>TestNearest<cr>", desc = "Nearest" },
      { "<leader>tf", "<cmd>TestFile<cr>", desc = "File" },
      { "<leader>ta", "<cmd>TestSuite<cr>", desc = "All" },
      { "<leader>tl", "<cmd>TestLast<cr>", desc = "Last" },
      { "<leader>tv", "<cmd>TestVisit<cr>", desc = "Visit" },
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
