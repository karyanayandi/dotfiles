-- luacheck: globals vim

return {
  "kyazdani42/nvim-tree.lua",
  config = function()
    local icons = require "config.icons"

    local function on_attach(bufnr)
      local api = require "nvim-tree.api"

      local function opts(desc)
        return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
      end

      api.config.mappings.default_on_attach(bufnr)

      vim.keymap.set("n", "l", api.node.open.edit, opts "Open")
      vim.keymap.set("n", "o", api.node.open.edit, opts "Open")
      vim.keymap.set("n", "<CR>", api.node.open.edit, opts "Open")
      vim.keymap.set("n", "v", api.node.open.vertical, opts "Open: Vertical Split")
      vim.keymap.set("n", "h", api.node.navigate.parent_close, opts "Close Directory")
    end

    require("nvim-tree").setup {
      on_attach = on_attach,
      hijack_directories = {
        enable = false,
      },
      -- filters = {
      --   custom = { ".git" },
      --   exclude = { ".gitignore", ".env", "~partytown", ".contentlayer", "dist", ".github", "neogit" },
      -- },
      update_cwd = true,
      renderer = {
        add_trailing = false,
        group_empty = false,
        highlight_git = false,
        highlight_opened_files = "none",
        root_folder_modifier = ":t",
        indent_markers = {
          enable = false,
          icons = {
            corner = icons.tree.IndentCorner,
            edge = icons.tree.IndentEdge,
            none = "  ",
          },
        },
        icons = {
          webdev_colors = true,
          git_placement = "before",
          padding = " ",
          symlink_arrow = icons.tree.SymlinkArrow,
          show = {
            file = true,
            folder = true,
            folder_arrow = true,
            git = true,
          },
          glyphs = {
            default = icons.tree.File,
            symlink = icons.tree.Symlink,
            folder = {
              arrow_open = icons.ui.ArrowOpen,
              arrow_closed = icons.ui.ArrowClosed,
              default = icons.tree.Folder,
              open = icons.tree.OpenFolder,
              empty = icons.tree.EmptyFolder,
              empty_open = icons.tree.EmptyOpenFolder,
              symlink = icons.tree.Symlink,
              symlink_open = icons.tree.Symlink,
            },
            git = {
              unstaged = icons.git.Unstaged,
              staged = icons.git.Staged,
              unmerged = icons.git.Merged,
              renamed = icons.git.Rename,
              untracked = icons.git.Untracked,
              deleted = icons.git.Remove,
              ignored = icons.git.Ignore,
            },
          },
        },
      },
      diagnostics = {
        enable = true,
        icons = {
          hint = icons.diagnostics.Hint,
          info = icons.diagnostics.Information,
          warning = icons.diagnostics.Warning,
          error = icons.diagnostics.Error,
        },
      },
      update_focused_file = {
        enable = true,
        update_cwd = true,
        ignore_list = {},
      },
      git = {
        enable = true,
        ignore = false,
        timeout = 500,
      },
      view = {
        width = 30,
        side = "left",
        number = false,
        relativenumber = false,
      },
    }
  end,
}
