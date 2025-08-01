-- luacheck: globals vim
-- luacheck: ignore 631

return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  config = function()
    local setup = {
      preset = "classic",
      Plugins = {
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
        mappings = false,
      },
      win = {
        border = "none",
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

    local whichkey_opts = {
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
        group = "AI",
      },
      {
        "<leader>aa",
        "<cmd>CopilotChatToggle<cr>",
        desc = "Toggle",
      },
      {
        "<leader>aA",
        "<cmd>CopilotChatAgents<cr>",
        desc = "Select Agents",
      },
      {
        "<leader>ac",
        "<cmd>CopilotChatReset<cr>",
        desc = "Clear buffer and chat history",
      },
      {
        "<leader>ai",
        function()
          local input = vim.fn.input "Ask Copilot: "
          if input ~= "" then
            vim.cmd("CopilotChat " .. input)
          end
        end,
        desc = "Ask input",
      },
      {
        "<leader>am",
        "<cmd>CopilotChatModels<cr>",
        desc = "Select Models",
      },
      {
        "<leader>b",
        group = "Buffer",
      },
      {
        "<leader>bb",
        "<cmd>lua require('telescope.builtin').buffers(require('telescope.themes').get_ivy{previewer = false, initial_mode='normal'})<cr>",
        desc = "Buffer List",
      },
      {
        "<leader>d",
        "<cmd>:lua require('snacks').dashboard()<cr>",
        desc = "Dashboard",
      },
      { "<leader>D", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics" },
      {
        "<leader>e",
        "<cmd>NvimTreeToggle<cr>",
        desc = "Explorer",
      },
      {
        "<leader>q",
        "<cmd>lua require('config.functions').smart_quit()<CR>",
        desc = "Quit",
      },
      {
        "<leader>w",
        "<cmd>w<CR>",
        desc = "Write",
      },
      {
        "<leader>ao",
        "<cmd>lua _OPENCODE_TOGGLE()<CR>",
        desc = "Toggle",
      },
      {
        "<leader>/",
        '<cmd>lua require("Comment.api").toggle.linewise.current()<CR>',
        desc = "Comment",
      },
      {
        "<leader>P",
        "<cmd>lua require('telescope').extensions.projects.projects()<cr>",
        desc = "Projects",
      },
      {
        "<leader>p",
        group = "Package",
      },
      {
        "<leader>po",
        "<cmd>Lazy<cr>",
        desc = "Overview",
      },
      {
        "<leader>pi",
        "<cmd>Lazy install<cr>",
        desc = "Install",
      },
      {
        "<leader>pl",
        "<cmd>Lazy log<cr>",
        desc = "Log",
      },
      {
        "<leader>ps",
        "<cmd>Lazy sync<cr>",
        desc = "Sync",
      },
      {
        "<leader>pc",
        "<cmd>Lazy check<cr>",
        desc = "Check",
      },
      {
        "<leader>px",
        "<cmd>Lazy clean<cr>",
        desc = "Clean",
      },
      {
        "<leader>pu",
        "<cmd>Lazy update<cr>",
        desc = "Update",
      },
      {
        "<leader>pd",
        "<cmd>Lazy debug<cr>",
        desc = "Debug",
      },
      {
        "<leader>pp",
        "<cmd>Lazy profile<cr>",
        desc = "Profile",
      },
      {
        "<leader>pr",
        "<cmd>Lazy restore<cr>",
        desc = "Restore",
      },
      {
        "<leader>o",
        group = "Option",
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
        "<leader>on",
        '<cmd>lua require("config.functions").toggle_option("number")<cr>',
        desc = "Number",
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
        "<leader>r",
        group = "Replace",
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
        "<leader>f",
        group = "Find",
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
        "<cmd>lua require('telescope').extensions.undo.undo()<cr>",
        desc = "Undo History",
      },
      {
        "<leader>g",
        group = "Git",
      },
      {
        "<leader>gg",
        "<cmd>lua _LAZYGIT_TOGGLE()<CR>",
        desc = "Lazygit",
      },
      {
        "<leader>gl",
        "<cmd>lua _LAZYGIT_LOG_TOGGLE()<CR>",
        desc = "Lazygit log",
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
        "<leader>gL",
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
      {
        "<leader>l",
        group = "LSP",
      },
      {
        "<leader>li",
        "<cmd>LspInfo<cr>",
        desc = "Info",
      },
      {
        "<leader>lc",
        "<cmd>lua vim.lsp.buf.code_action()<cr>",
        desc = "Code Action",
      },
      {
        "<leader>lh",
        "<cmd>ToggleInlayHint<cr>",
        desc = "Toggle Inlay Hint",
      },
      {
        "<leader>lH",
        "<cmd>lua require('illuminate').toggle()<cr>",
        desc = "Toggle Doc HL",
      },
      {
        "<leader>lI",
        "<cmd>LspInstall<cr>",
        desc = "Installer Info",
      },
      {
        "<leader>lj",
        "<cmd>lua vim.diagnostic.goto_next({buffer=0})<cr>",
        desc = "Next Diagnostic",
      },
      {
        "<leader>lk",
        "<cmd>lua vim.diagnostic.goto_prev({buffer=0})<cr>",
        desc = "Prev Diagnostic",
      },
      {
        "<leader>lm",
        "<cmd>Mason<cr>",
        desc = "Mason Info",
      },
      {
        "<leader>lq",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Quickfix",
      },
      {
        "<leader>lr",
        "<cmd>lua vim.lsp.buf.rename()<cr>",
        desc = "Rename",
      },
      {
        "<leader>lR",
        "<cmd>Trouble lsp toggle focus=false<cr>",
        desc = "References",
      },
      {
        "<leader>ls",
        "<cmd>Telescope lsp_document_symbols<cr>",
        desc = "Document Symbols",
      },
      {
        "<leader>lS",
        "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>",
        desc = "Workspace Symbols",
      },
      {
        "<leader>ld",
        '<cmd>lua require("config.functions").toggle_diagnostics()<cr>',
        desc = "Toggle Diagnostics",
      },
      {
        "<leader>lf",
        "<cmd>AutoFormatOnSaveToggle<cr>",
        desc = "Toggle autoformat-on-save",
      },
      {
        "<leader>lt",
        "<cmd>TSToggle highlight<cr>",
        desc = "Toggle Treesitter Highlight",
      },
      {
        "<leader>lT",
        "<cmd>TodoTrouble keywords=TODO,FIX,FIXME<cr>",
        desc = "Todo Diagnostics",
      },
      {
        "<leader>lu",
        "<cmd>LuaSnipUnlinkCurrent<cr>",
        desc = "Unlink Snippet",
      },
      {
        "<leader>/",
        '<ESC><CMD>lua require("Comment.api").toggle.linewise(vim.fn.visualmode())<CR>',
        desc = "Comment",
        mode = "v",
      },
      {
        "<leader>s",
        ":'<,'>sort<CR>",
        desc = "Sort selected lines",
        mode = "v",
      },
    }

    require("which-key").setup(setup)
    require("which-key").add(mappings, whichkey_opts)
  end,
}
