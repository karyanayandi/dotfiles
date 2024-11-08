-- luacheck: globals vim
-- luacheck: ignore 631

return {
  "goolord/alpha-nvim",
  event = "VimEnter",
  config = function()
    local dashboard = require "alpha.themes.dashboard"
    local icons = require "config.icons"

    dashboard.section.header.val = {
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
    }

    dashboard.section.buttons.val = {
      dashboard.button("f", icons.documents.Files .. " Find file", ":Telescope find_files <CR>"),
      dashboard.button("e", icons.ui.NewFile .. " New file", ":ene <BAR> startinsert <CR>"),
      dashboard.button(
        "p",
        icons.git.Repo .. " Find project",
        ":lua require('telescope').extensions.projects.projects()<CR>"
      ),
      dashboard.button("r", icons.ui.History .. " Recent files", ":Telescope oldfiles <CR>"),
      dashboard.button("t", icons.ui.List .. " Find text", ":Telescope live_grep <CR>"),
      dashboard.button("c", icons.ui.GearOutline .. " Config", ":e ~/.config/nvim/init.lua <CR>"),
      dashboard.button("u", icons.ui.CloudDownload .. " Update", ":Lazy update<CR>"),
      dashboard.button("q", icons.ui.SignOut .. " Quit", ":qa<CR>"),
    }

    dashboard.section.footer.opts.hl = "Constant"
    dashboard.section.header.opts.hl = "Macro"
    dashboard.section.buttons.opts.hl = "Macro"

    vim.api.nvim_create_autocmd("User", {
      pattern = "LazyVimStarted",
      callback = function()
        ---@diagnostic disable-next-line: different-requires
        local stats = require("lazy").stats()
        local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
        local pad_footer = string.rep(" ", 8)
        dashboard.section.footer.val = pad_footer .. "⚡ Neovim loaded " .. stats.count .. " plugins in " .. ms .. "ms"
        pcall(dashboard.refresh)
      end,
    })

    dashboard.opts.opts.noautocmd = true
    require("alpha").setup(dashboard.opts)
  end,
}
