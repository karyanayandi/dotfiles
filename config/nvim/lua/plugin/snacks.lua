-- luacheck: globals Snacks
-- luacheck: globals vim
-- luacheck: globals M

local icons = require "config.icons"

return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    bigfile = { enabled = true },
    dashboard = {
      width = 60,
      row = nil,
      col = nil,
      pane_gap = 4,
      autokeys = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
      preset = {
        pick = nil,
        keys = {
          {
            icon = icons.documents.File,
            key = "e",
            desc = "New File",
            action = ":ene | startinsert",
          },
          {
            icon = icons.documents.Files,
            key = "f",
            desc = "Find File",
            action = ":Telescope find_files",
          },
          {
            icon = icons.ui.History,
            key = "r",
            desc = "Recent Files",
            action = ":Telescope oldfiles",
          },
          {
            icon = icons.ui.List,
            key = "t",
            desc = "Find Text",
            action = ":Telescope live_grep",
          },
          {
            icon = icons.git.Repo,
            key = "p",
            desc = "Find Project",
            action = ":lua require('telescope').extensions.projects.projects()",
          },
          {
            icon = icons.ui.GearOutline,
            key = "c",
            desc = "Config",
            action = ":e ~/.config/dotfiles/shared/config/neovim/init.lua",
          },
          {
            icon = icons.ui.CloudDownload,
            key = "u",
            desc = "Update",
            action = ":Lazy update",
          },
        },
      },
      formats = {
        icon = function(item)
          if item.file and item.icon == "file" or item.icon == "directory" then
            return M.icon(item.file, item.icon)
          end
          return { item.icon, width = 2, hl = "icon" }
        end,
        footer = { "%s", align = "center" },
        header = { "%s", align = "center" },
      },
      sections = {
        { section = "terminal", cmd = "echo 'Code Editor' | cowsay", hl = "header", padding = 1, indent = 8 },
        { section = "keys", gap = 1, padding = 1 },
        { section = "startup" },
      },
    },
    debug = { enabled = false },
    dim = { enabled = false },
    git = { enabled = false },
    gitbrowse = {
      enabled = true,
      notify = true,
      what = "file",
      branch = nil,
      line_start = nil,
      line_end = nil,
      remote_patterns = {
        { "^(https?://.*)%.git$", "%1" },
        { "^git@(.+):(.+)%.git$", "https://%1/%2" },
        { "^git@(.+):(.+)$", "https://%1/%2" },
        { "^git@(.+)/(.+)$", "https://%1/%2" },
        { "^ssh://git@(.*)$", "https://%1" },
        { "^ssh://([^:/]+)(:%d+)/(.*)$", "https://%1/%3" },
        { "^ssh://([^/]+)/(.*)$", "https://%1/%2" },
        { "ssh%.dev%.azure%.com/v3/(.*)/(.*)$", "dev.azure.com/%1/_git/%2" },
        { "^https://%w*@(.*)", "https://%1" },
        { "^git@(.*)", "https://%1" },
        { ":%d+", "" },
        { "%.git$", "" },
      },
      url_patterns = {
        ["github%.com"] = {
          branch = "/tree/{branch}",
          file = "/blob/{branch}/{file}#L{line_start}-L{line_end}",
          commit = "/commit/{commit}",
        },
        ["gitlab%.com"] = {
          branch = "/-/tree/{branch}",
          file = "/-/blob/{branch}/{file}#L{line_start}-L{line_end}",
          commit = "/-/commit/{commit}",
        },
        ["bitbucket%.org"] = {
          branch = "/src/{branch}",
          file = "/src/{branch}/{file}#lines-{line_start}-L{line_end}",
          commit = "/commits/{commit}",
        },
      },
    },
    health = { enabled = false },
    indent = {
      enabled = true,
      priority = 1,
      char = icons.ui.Pipe,
      only_scope = false,
      only_current = false,
      hl = "SnacksIndent",
      scope = {
        enabled = true,
        priority = 200,
        char = icons.ui.Pipe,
        underline = false,
        only_current = false,
        hl = "SnacksIndentScope",
      },
      chunk = {
        enabled = false,
        only_current = false,
        priority = 200,
        hl = "SnacksIndentChunk",
        char = {
          corner_top = "┌",
          corner_bottom = "└",
          horizontal = "─",
          vertical = icons.ui.Pipe,
          arrow = ">",
        },
      },
      blank = {
        char = " ",
        hl = "SnacksIndentBlank",
      },
      animate = {
        enabled = true,
        duration = 20,
        easing = "linear",
        fps = 75,
      },
      filter = function(buf)
        return vim.g.snacks_indent ~= false and vim.b[buf].snacks_indent ~= false and vim.bo[buf].buftype == ""
      end,
    },
    input = {
      enabled = true,
      icon = " ",
      icon_hl = "SnacksInputIcon",
      icon_pos = "left",
      prompt_pos = "title",
      win = { style = "input" },
      expand = true,
      backdrop = false,
      position = "float",
      border = "rounded",
      title_pos = "center",
      height = 1,
      width = 60,
      relative = "editor",
      noautocmd = true,
      row = 2,
      -- relative = "cursor",
      -- row = -3,
      -- col = 0,
      wo = {
        winhighlight = "NormalFloat:SnacksInputNormal,FloatBorder:SnacksInputBorder,FloatTitle:SnacksInputTitle",
        cursorline = false,
      },
      bo = {
        filetype = "snacks_input",
        buftype = "prompt",
      },
      b = {
        completion = false,
      },
      keys = {
        n_esc = { "<esc>", { "cmp_close", "cancel" }, mode = "n", expr = true },
        i_esc = { "<esc>", { "cmp_close", "stopinsert" }, mode = "i", expr = true },
        i_cr = { "<cr>", { "cmp_accept", "confirm" }, mode = "i", expr = true },
        i_tab = { "<tab>", { "cmp_select_next", "cmp" }, mode = "i", expr = true },
        i_ctrl_w = { "<c-w>", "<c-s-w>", mode = "i", expr = true },
        i_up = { "<up>", { "hist_up" }, mode = { "i", "n" } },
        i_down = { "<down>", { "hist_down" }, mode = { "i", "n" } },
        q = "cancel",
      },
    },
    lazygit = { enabled = false },
    notifier = {
      enabled = true,
      width = { min = 40, max = 0.4 },
      height = { min = 1, max = 0.6 },
      margin = { top = 0, right = 1, bottom = 0 },
      padding = true,
      sort = { "level", "added" },
      level = vim.log.levels.TRACE,
      icons = {
        error = icons.diagnostics.Error,
        warn = icons.diagnostics.Warning,
        info = icons.diagnostics.Info,
        debug = icons.ui.Bug,
        trace = icons.ui.Pencil,
      },
      keep = function()
        return vim.fn.getcmdpos() > 0
      end,
      style = "compact",
      top_down = true,
      date_format = "%R",
      more_format = " ↓ %d lines ",
      refresh = 50,
    },
    picker = {
      enabled = true,
      ui_select = true,
    },
    profiler = { enabled = false },
    quickfile = { enabled = true },
    scratch = { enabled = false },
    scroll = { enabled = true },
    statuscolumn = {
      enabaled = true,
      left = { "mark", "sign" },
      right = { "fold", "git" },
      folds = {
        open = true,
        git_hl = true,
      },
      git = {
        patterns = { "GitSign", "MiniDiffSign" },
      },
      refresh = 50,
    },
    terminal = {
      enabled = true,
      win = {
        style = "terminal",
        position = "bottom",
      },
    },
    toggle = { enabled = false },
    words = { enabled = false },
    zen = { enabled = false },
  },
  config = function(_, opts)
    require("snacks").setup(opts)

    -- Terminal window navigation (replaces toggleterm set_terminal_keymaps)
    vim.api.nvim_create_autocmd("TermOpen", {
      pattern = "term://*",
      callback = function()
        local map_opts = { noremap = true, buffer = 0 }
        vim.keymap.set("t", "<C-h>", [[<C-\><C-n><C-W>h]], map_opts)
        vim.keymap.set("t", "<C-j>", [[<C-\><C-n><C-W>j]], map_opts)
        vim.keymap.set("t", "<C-k>", [[<C-\><C-n><C-W>k]], map_opts)
        vim.keymap.set("t", "<C-l>", [[<C-\><C-n><C-W>l]], map_opts)
      end,
    })

    -- lazygit
    function _LAZYGIT_TOGGLE()
      Snacks.terminal.toggle("lazygit", {
        interactive = true,
        win = { position = "float", border = "rounded" },
      })
    end

    -- lazygit log
    function _LAZYGIT_LOG_TOGGLE()
      Snacks.terminal.toggle("lazygit log", {
        interactive = true,
        win = { position = "float", border = "rounded" },
      })
    end

    -- opencode
    function _OPENCODE_TOGGLE()
      if vim.env.TMUX ~= nil and vim.env.TMUX ~= "" then
        local pane_id = vim.g.opencode_tmux_pane
        if pane_id then
          vim.fn.system("tmux display-message -t " .. pane_id .. " -p '#{pane_id}' 2>/dev/null")
          if vim.v.shell_error == 0 then
            vim.fn.system("tmux kill-pane -t " .. pane_id)
            vim.g.opencode_tmux_pane = nil
            return
          else
            vim.g.opencode_tmux_pane = nil
          end
        end
        local result = vim.fn.system "tmux split-window -h -p 40 -P -F '#{pane_id}' 'opencode'"
        vim.g.opencode_tmux_pane = vim.fn.trim(result)
      else
        Snacks.terminal.toggle("opencode", {
          interactive = true,
          win = { position = "right", width = 0.4 },
        })
      end
    end
  end,
  keys = {
    {
      "<leader>bc",
      function()
        Snacks.bufdelete()
      end,
      desc = "Close",
    },
    {
      "<leader>bd",
      function()
        Snacks.bufdelete()
      end,
      desc = "Delete Buffer",
    },
    {
      "<leader>bD",
      function()
        Snacks.bufdelete.all()
      end,
      desc = "Delete All Buffer",
    },
    {
      "<leader>gB",
      function()
        Snacks.gitbrowse()
      end,
      mode = { "n", "v" },
      desc = "Browse",
    },
    {
      "<leader>oN",
      function()
        Snacks.notifier.hide()
      end,
      desc = "Dismiss All Notifications",
    },
    {
      "<C-t>",
      function()
        Snacks.terminal.toggle()
      end,
      mode = { "n", "i", "t" },
      desc = "Toggle Terminal",
    },
    {
      ";o",
      function()
        _OPENCODE_TOGGLE()
      end,
      mode = { "n", "i" },
      desc = "Toggle OpenCode",
    },
  },
}
