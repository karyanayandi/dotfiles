-- luacheck: globals vim

local function projects_picker()
  local ok, project_nvim = pcall(require, "project_nvim")
  if not ok then
    vim.notify("project_nvim not available", vim.log.levels.WARN)
    return
  end
  local projects = project_nvim.get_recent_projects()
  local fzf = require "fzf-lua"
  fzf.fzf_exec(projects, {
    prompt = "Projects> ",
    actions = {
      ["default"] = function(selected)
        if selected and selected[1] then
          vim.fn.chdir(selected[1])
          vim.notify("Changed to: " .. selected[1], vim.log.levels.INFO)
        end
      end,
    },
  })
end

-- expose globally for keymaps / which-key
_G._PROJECTS_PICKER = projects_picker

return {
  "ibhagwan/fzf-lua",
  event = "BufEnter",
  cmd = { "FzfLua" },
  dependencies = {
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
      end,
    },
  },
  config = function()
    local fzf = require "fzf-lua"
    local colors = require("base16-colorscheme").colors

    vim.api.nvim_set_hl(0, "FzfLuaPreviewNormal", { bg = colors.base01, fg = colors.base05 })
    vim.api.nvim_set_hl(0, "FzfLuaPreviewBorder", { bg = colors.base01, fg = colors.base05 })

    fzf.setup {
      "telescope",
      winopts = {
        backdrop = false,
        height = 0.85,
        width = 0.80,
        row = 0.35,
        col = 0.55,
        preview = {
          border = "none",
          wrap = "nowrap",
          hidden = "nohidden",
          vertical = "down:45%",
          horizontal = "right:60%",
          layout = "flex",
          flip_columns = 120,
          title = true,
          scrollbar = "float",
          scrolloff = "-2",
          scrollchars = { "█", "" },
          delay = 100,
          winopts = {
            winhl = "Normal:FzfLuaPreviewNormal,NormalNC:FzfLuaPreviewNormal,FloatBorder:FzfLuaPreviewBorder",
          },
        },
      },
      fzf_opts = {
        ["--ansi"] = true,
        ["--info"] = "inline",
        ["--height"] = "100%",
        ["--layout"] = "reverse",
        ["--border"] = "none",
      },
      keymap = {
        builtin = {
          ["<C-/>"] = "toggle-help",
          ["<C-d>"] = "preview-page-down",
          ["<C-u>"] = "preview-page-up",
          ["<C-f>"] = "preview-page-down",
          ["<C-b>"] = "preview-page-up",
          ["<S-left>"] = "preview-reset",
        },
        fzf = {
          ["ctrl-c"] = "abort",
          ["ctrl-a"] = "toggle-all",
          ["ctrl-q"] = "select-all+accept",
          ["ctrl-s"] = "toggle-sort",
          ["ctrl-j"] = "down",
          ["ctrl-k"] = "up",
        },
      },
      actions = {
        files = {
          ["default"] = fzf.actions.file_edit_or_qf,
          ["ctrl-s"] = fzf.actions.file_split,
          ["ctrl-v"] = fzf.actions.file_vsplit,
          ["ctrl-t"] = fzf.actions.file_tabedit,
          ["alt-q"] = fzf.actions.file_sel_to_qf,
        },
        buffers = {
          ["default"] = fzf.actions.buf_edit,
          ["ctrl-s"] = fzf.actions.buf_split,
          ["ctrl-v"] = fzf.actions.buf_vsplit,
          ["ctrl-t"] = fzf.actions.buf_tabedit,
          ["ctrl-d"] = fzf.actions.buf_del,
        },
      },
      defaults = {
        file_ignore_patterns = {
          "%.7z",
          "%.burp",
          "%.bz2",
          "%.cache",
          "%.class",
          "%.dll",
          "%.docx",
          "%.dylib",
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
          "%.tar%.gz",
          "%.zip",
          "%.dart_tool/",
          "%.git/",
          "%.gradle/",
          "%.idea/",
          "%.settings/",
          "%.storybook/",
          "%.vale/",
          "%.vscode/",
          "__pycache__/",
          "build/",
          "dist/",
          "docs/",
          "gradle/",
          "node_modules/",
          "smalljre_.+/",
          "target/",
          "vendor/",
        },
      },
      files = {
        git_icons = true,
        file_icons = true,
        color_icons = true,
        fd_opts = "--color=never --type f --hidden --follow --exclude .git",
      },
      grep = {
        rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=4096 -e",
      },
      buffers = {
        previewer = false,
      },
      git = {
        branches = {
          previewer = false,
        },
      },
      lsp = {
        symbols = {
          symbol_icons = {
            File = "󰈙",
            Module = "",
            Namespace = "󰦮",
            Package = "",
            Class = "󰌗",
            Method = "󰆧",
            Property = "",
            Field = "",
            Constructor = "",
            Enum = "󰒻",
            Interface = "",
            Function = "󰊕",
            Variable = "󰫧",
            Constant = "󰏿",
            String = "󰉿",
            Number = "󰎠",
            Boolean = "󱓂",
            Array = "󰅪",
            Object = "󰅩",
            Key = "󰌋",
            Null = "󰌚",
            EnumMember = "",
            Struct = "󰌗",
            Event = "",
            Operator = "󰆕",
            TypeParameter = "󰊄",
          },
        },
      },
    }
  end,
}
