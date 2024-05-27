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
      -- remove_keymaps = false,
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
          enable = true,
          icons = {
            corner = "└ ",
            edge = "│ ",
            none = "  ",
          },
        },
        icons = {
          webdev_colors = true,
          git_placement = "before",
          padding = " ",
          symlink_arrow = " ➛ ",
          show = {
            file = true,
            folder = true,
            folder_arrow = true,
            git = true,
          },
          glyphs = {
            default = "",
            symlink = "",
            folder = {
              arrow_open = icons.ui.ArrowOpen,
              arrow_closed = icons.ui.ArrowClosed,
              default = "",
              open = "",
              empty = "",
              empty_open = "",
              symlink = "",
              symlink_open = "",
            },
            git = {
              unstaged = "",
              staged = "S",
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
          hint = "",
          info = "",
          warning = "",
          error = "",
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
        -- hide_root_folder = false,
        side = "left",
        number = false,
        relativenumber = false,
      },
    }
  end,
}
