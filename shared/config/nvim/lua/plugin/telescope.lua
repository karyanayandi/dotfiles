-- luacheck: globals vim

return {
  "nvim-telescope/telescope.nvim",
  event = "Bufenter",
  cmd = { "Telescope" },
  dependencies = {
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release",
      config = function()
        require("telescope").load_extension "fzf"
      end,
    },
    {
      "ahmedkhalf/project.nvim",
      config = function()
        require("project_nvim").setup {
          active = true,
          on_config_done = nil,
          manual_mode = false,
          detection_methods = { "pattern" },
          patterns = {
            ".git",
            "_darcs",
            ".hg",
            ".bzr",
            ".svn",
            "Makefile",
            "package.json",
            "Cargo.toml",
            "deno.json",
          },
          show_hidden = false,
          silent_chdir = true,
          ignore_lsp = {},
          exclude_dirs = { "dist", "build", ".next", "node_modules", ".github" },
          datapath = vim.fn.stdpath "data",
        }

        require("telescope").load_extension "projects"
      end,
    },
    {
      "nvim-telescope/telescope-media-files.nvim",
      config = function()
        require("telescope").load_extension "media_files"
      end,
    },
    {
      "debugloop/telescope-undo.nvim",
      config = function()
        require("telescope").load_extension "undo"
      end,
    },
  },
  config = function()
    local actions = require "telescope.actions"
    local icons = require "config.icons"

    require("telescope").setup {
      defaults = {
        prompt_prefix = icons.ui.Telescope .. " ",
        selection_caret = icons.ui.CaretRight,
        path_display = { "smart" },
        file_ignore_patterns = {
          "%.7z",
          "%.burp",
          "%.bz2",
          "%.cache",
          "%.class",
          "%.dll",
          "%.docx",
          "%.dylib",
          "%.env",
          "%.epub",
          "%.exe",
          "%.flac",
          "%.ico",
          "%.ipynb",
          "%.jar",
          "%.lock",
          "%.met",
          "%.mkv",
          "%.mp4",
          "%.pdb",
          "%.pdf",
          "%.rar",
          "%.sqlite3",
          "%.tar",
          "%.tar.gz",
          "%.zip",
          ".dart_tool/",
          ".git/",
          ".gradle/",
          ".idea/",
          ".settings/",
          ".storybook/*",
          ".vale/",
          ".vscode/",
          "__pycache__/",
          "__pycache__/*",
          "build/",
          "dist/",
          "docs/",
          "gradle/",
          "node_modules/",
          "node_modules/*",
          "smalljre_*/*",
          "target/",
          "vendor/*",
        },
        mappings = {
          i = {
            ["<C-n>"] = actions.cycle_history_next,
            ["<C-p>"] = actions.cycle_history_prev,
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-c>"] = actions.close,
            ["<Down>"] = actions.move_selection_next,
            ["<Up>"] = actions.move_selection_previous,
            ["<CR>"] = actions.select_default,
            ["<C-s>"] = actions.select_horizontal,
            ["<C-v>"] = actions.select_vertical,
            ["<C-t>"] = actions.select_tab,
            ["<c-d>"] = require("telescope.actions").delete_buffer,
            ["<PageUp>"] = actions.results_scrolling_up,
            ["<PageDown>"] = actions.results_scrolling_down,
            ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
            ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
            ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
            ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
            ["<C-l>"] = actions.complete_tag,
            ["<C-_>"] = actions.which_key,
          },
          n = {
            ["<esc>"] = actions.close,
            ["<CR>"] = actions.select_default,
            ["<C-x>"] = actions.select_horizontal,
            ["<C-v>"] = actions.select_vertical,
            ["<C-t>"] = actions.select_tab,
            ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
            ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
            ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
            ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
            ["j"] = actions.move_selection_next,
            ["k"] = actions.move_selection_previous,
            ["H"] = actions.move_to_top,
            ["M"] = actions.move_to_middle,
            ["L"] = actions.move_to_bottom,
            ["q"] = actions.close,
            ["dd"] = require("telescope.actions").delete_buffer,
            ["s"] = actions.select_horizontal,
            ["v"] = actions.select_vertical,
            ["t"] = actions.select_tab,
            ["<Down>"] = actions.move_selection_next,
            ["<Up>"] = actions.move_selection_previous,
            ["gg"] = actions.move_to_top,
            ["G"] = actions.move_to_bottom,
            ["<C-u>"] = actions.preview_scrolling_up,
            ["<C-d>"] = actions.preview_scrolling_down,
            ["<PageUp>"] = actions.results_scrolling_up,
            ["<PageDown>"] = actions.results_scrolling_down,
            ["?"] = actions.which_key,
          },
        },
      },
      pickers = {},
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case",
        },
        workspaces = {
          keep_insert = true,
          open = { "NvimTreeOpen", "Telescope find_files" },
        },
        media_files = {
          filetypes = { "png", "webp", "jpg", "jpeg" },
          find_cmd = "rg",
        },
        undo = {
          side_by_side = true,
          layout_strategy = "vertical",
          layout_config = {
            preview_height = 0.8,
          },
        },
      },
    }
  end,
}
