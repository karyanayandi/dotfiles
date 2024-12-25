-- luacheck: globals Snacks
-- luacheck: globals vim

local icons = require "config.icons"

return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    animate = {
      -- TODO: add toggle to option seting
      duration = 20,
      easing = "linear",
      fps = 60,
    },
    bigfile = { enabled = true },
    dashboard = {
      enabled = true,
      event = "VimEnter",
      width = 60,
      row = nil,
      col = nil,
      pane_gap = 4,
      autokeys = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", -- autokey sequence
      preset = {
        ---@type fun(cmd:string, opts:table)|nil
        pick = nil,
        ---@type snacks.dashboard.Item[]
        keys = {
          {
            icon = icons.ducuments.NewFile,
            key = "e",
            desc = "New File",
            action = ":ene | startinsert",
          },
          {
            icon = icons.ducuments.Files,
            key = "f",
            desc = "Find File",
            action = ":Telescope find_files",
          },
          {
            icon = icons.ui.History,
            key = "r",
            desc = "Recent Files",
            action = ":lua Snacks.dashboard.pick('oldfiles')",
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
            action = ":e ~/.config/dotfiles/home/neovim/default.nix",
          },
          {
            icon = icons.ui.CloudDownload,
            key = "u",
            desc = "Update",
            action = ":Lazy update",
          },
          { icon = icons.ui.SignOut, key = "q", desc = "Quit", action = ":qa" },
        },
        header = {
          [[                                                                  ]],
          [[                                                                  ]],
          [[                                                                  ]],
          [[                                                                  ]],
          [[                                                                  ]],
          [[                                                                  ]],
          [[                                                                  ]],
          [[                                                                  ]],
          [[                                                                  ]],
          [[  ▄████████ ████████▄   ▄█      ███      ▄██████▄     ▄████████   ]],
          [[  ███    ███ ███   ▀███ ███  ▀█████████▄ ███    ███   ███    ███  ]],
          [[  ███    █▀  ███    ███ ███▌    ▀███▀▀██ ███    ███   ███    ███  ]],
          [[ ▄███▄▄▄     ███    ███ ███▌     ███   ▀ ███    ███  ▄███▄▄▄▄██▀  ]],
          [[▀▀███▀▀▀     ███    ███ ███▌     ███     ███    ███ ▀▀███▀▀▀▀▀    ]],
          [[  ███    █▄  ███    ███ ███      ███     ███    ███ ▀███████████  ]],
          [[  ███    ███ ███   ▄███ ███      ███     ███    ███   ███    ███  ]],
          [[  ██████████ ████████▀  █▀      ▄████▀    ▀██████▀    ███    ███  ]],
          [[                                                      ███    ███  ]],
          [[                                                                  ]],
          [[                                                                  ]],
          [[                                                                  ]],
          [[                                                                  ]],
        },
        formats = {
          footer = { "%s", align = "center" },
          header = { "%s", align = "center" },
          file = function(item, ctx)
            local fname = vim.fn.fnamemodify(item.file, ":~")
            fname = ctx.width and #fname > ctx.width and vim.fn.pathshorten(fname) or fname
            if #fname > ctx.width then
              local dir = vim.fn.fnamemodify(fname, ":h")
              local file = vim.fn.fnamemodify(fname, ":t")
              if dir and file then
                file = file:sub(-(ctx.width - #dir - 2))
                fname = dir .. "/…" .. file
              end
            end
            local dir, file = fname:match "^(.*)/(.+)$"
            return dir and { { dir .. "/", hl = "dir" }, { file, hl = "file" } } or { { fname, hl = "file" } }
          end,
        },
        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
          { section = "startup" },
        },
      },
    },
    indent = { enabled = false },
    input = { enabled = false },
    notifier = {
      enabled = false,
      timeout = 3000,
    },
    quickfile = { enabled = false },
    scroll = { enabled = false },
    statuscolumn = { enabled = false },
    words = { enabled = false },
    -- styles = {
    -- notification = {
    -- wo = { wrap = true } -- Wrap notifications
    -- },
    -- },
    zen = {
      enabled = false,
    },
  },
  keys = {
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

    --   {
    --     "<leader>.",
    --     function()
    --       Snacks.scratch()
    --     end,
    --     desc = "Toggle Scratch Buffer",
    --   },
    --   {
    --     "<leader>S",
    --     function()
    --       Snacks.scratch.select()
    --     end,
    --     desc = "Select Scratch Buffer",
    --   },
    --   {
    --     "<leader>n",
    --     function()
    --       Snacks.notifier.show_history()
    --     end,
    --     desc = "Notification History",
    --   },
    --   {
    --     "<leader>cR",
    --     function()
    --       Snacks.rename.rename_file()
    --     end,
    --     desc = "Rename File",
    --   },
    --   {
    --     "<leader>gB",
    --     function()
    --       Snacks.gitbrowse()
    --     end,
    --     desc = "Git Browse",
    --     mode = { "n", "v" },
    --   },
    --   {
    --     "<leader>gb",
    --     function()
    --       Snacks.git.blame_line()
    --     end,
    --     desc = "Git Blame Line",
    --   },
    --   {
    --     "<leader>gf",
    --     function()
    --       Snacks.lazygit.log_file()
    --     end,
    --     desc = "Lazygit Current File History",
    --   },
    --   {
    --     "<leader>gg",
    --     function()
    --       Snacks.lazygit()
    --     end,
    --     desc = "Lazygit",
    --   },
    --   {
    --     "<leader>gl",
    --     function()
    --       Snacks.lazygit.log()
    --     end,
    --     desc = "Lazygit Log (cwd)",
    --   },
    --   {
    --     "<leader>un",
    --     function()
    --       Snacks.notifier.hide()
    --     end,
    --     desc = "Dismiss All Notifications",
    --   },
    --   {
    --     "<c-/>",
    --     function()
    --       Snacks.terminal()
    --     end,
    --     desc = "Toggle Terminal",
    --   },
    --   {
    --     "<c-_>",
    --     function()
    --       Snacks.terminal()
    --     end,
    --     desc = "which_key_ignore",
    --   },
    --   {
    --     "]]",
    --     function()
    --       Snacks.words.jump(vim.v.count1)
    --     end,
    --     desc = "Next Reference",
    --     mode = { "n", "t" },
    --   },
    --   {
    --     "[[",
    --     function()
    --       Snacks.words.jump(-vim.v.count1)
    --     end,
    --     desc = "Prev Reference",
    --     mode = { "n", "t" },
    --   },
    --   {
    --     "<leader>N",
    --     desc = "Neovim News",
    --     function()
    --       Snacks.win {
    --         file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
    --         width = 0.6,
    --         height = 0.6,
    --         wo = {
    --           spell = false,
    --           wrap = false,
    --           signcolumn = "yes",
    --           statuscolumn = " ",
    --           conceallevel = 3,
    --         },
    --       }
    --     end,
    --   },
  },
  -- init = function()
  --   vim.api.nvim_create_autocmd("User", {
  --     pattern = "VeryLazy",
  --     callback = function()
  --       -- Setup some globals for debugging (lazy-loaded)
  --       _G.dd = function(...)
  --         Snacks.debug.inspect(...)
  --       end
  --       _G.bt = function()
  --         Snacks.debug.backtrace()
  --       end
  --       vim.print = _G.dd -- Override print to use snacks for `:=` command
  --
  --       -- Create some toggle mappings
  --       Snacks.toggle.option("spell", { name = "Spelling" }):map "<leader>us"
  --       Snacks.toggle.option("wrap", { name = "Wrap" }):map "<leader>uw"
  --       Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map "<leader>uL"
  --       Snacks.toggle.diagnostics():map "<leader>ud"
  --       Snacks.toggle.line_number():map "<leader>ul"
  --       Snacks.toggle
  --         .option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
  --         :map "<leader>uc"
  --       Snacks.toggle.treesitter():map "<leader>uT"
  --       Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map "<leader>ub"
  --       Snacks.toggle.inlay_hints():map "<leader>uh"
  --       Snacks.toggle.indent():map "<leader>ug"
  --       Snacks.toggle.dim():map "<leader>uD"
  --     end,
  -- })
  -- end,
}
