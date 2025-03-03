return {
  "nvim-treesitter/nvim-treesitter",
  lazy = false,
  -- event = { "BufReadPost", "BufNewFile" },
  build = ":TSUpdate",
  dependencies = {
    {
      "JoosepAlviste/nvim-ts-context-commentstring",
      lazy = true,
      "nvim-treesitter/nvim-treesitter",
      config = function()
        require("nvim-treesitter.configs").setup {
          highlight = {
            enable = true,
          },
        }
      end,
    },
    {
      "nvim-treesitter/nvim-treesitter-textobjects",
      event = "VeryLazy",
    },
    {
      "windwp/nvim-ts-autotag",
      event = { "BufReadPre", "BufNewFile" },
      config = function()
        require("nvim-ts-autotag").setup {
          opts = {
            enable_close = true,
            enable_rename = true,
            enable_close_on_slash = false,
          },
          per_filetype = {
            ["html"] = {
              enable_close_on_slash = true,
            },
          },
        }
      end,
    },
    {
      "windwp/nvim-autopairs",
      event = "InsertEnter",
      config = function()
        require("nvim-autopairs").setup {
          map_char = {
            all = "(",
            tex = "{",
          },
          enable_check_bracket_line = false,
          check_ts = true,
          ts_config = {
            lua = { "string", "source" },
            javascript = { "string", "template_string" },
            java = false,
          },
          disable_filetype = { "TelescopePrompt", "spectre_panel", "snacks_dashboard", "snacks_terminal" },
          ignored_next_char = string.gsub([[ [%w%%%'%[%"%.] ]], "%s+", ""),
          enable_moveright = true,
          disable_in_macro = false,
          enable_afterquote = true,
          map_bs = true,
          map_c_w = false,
          disable_in_visualblock = false,
          fast_wrap = {
            map = "<M-w>",
            chars = { "{", "[", "(", '"', "'" },
            pattern = string.gsub([[ [%'%"%)%>%]%)%}%,] ]], "%s+", ""),
            offset = 0,
            end_key = "$",
            keys = "qwertyuiopzxcvbnmasdfghjkl",
            check_comma = true,
            highlight = "Search",
            highlight_grey = "Comment",
          },
        }

        local cmp_autopairs = require "nvim-autopairs.completion.cmp"
        require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done { map_char = { tex = "" } })
      end,
    },
  },
  config = function()
    require("nvim-treesitter.configs").setup {
      ensure_installed = {
        "astro",
        "bash",
        "c",
        "fish",
        "go",
        "javascript",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "rust",
        "svelte",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "vue",
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = "<nop>",
          node_decremental = "<bs>",
        },
      },
      ignore_install = { "" },
      matchup = {
        enable = true,
        disable_virtual_text = true,
        disable = { "html", "smali", "jsonc", "lua" },
      },
      highlight = {
        enable = true,
      },
      autopairs = {
        enable = true,
      },
      indent = { enable = true, disable = { "python" } },
      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ["af"] = "@function.outer",
            ["if"] = "@function.inner",
            ["at"] = "@class.outer",
            ["it"] = "@class.inner",
            ["ac"] = "@call.outer",
            ["ic"] = "@call.inner",
            ["aa"] = "@parameter.outer",
            ["ia"] = "@parameter.inner",
            ["al"] = "@loop.outer",
            ["il"] = "@loop.inner",
            ["ai"] = "@conditional.outer",
            ["ii"] = "@conditional.inner",
            ["a/"] = "@comment.outer",
            ["i/"] = "@comment.inner",
            ["ab"] = "@block.outer",
            ["ib"] = "@block.inner",
            ["as"] = "@statement.outer",
            ["is"] = "@scopename.inner",
            ["aA"] = "@attribute.outer",
            ["iA"] = "@attribute.inner",
            ["aF"] = "@frame.outer",
            ["iF"] = "@frame.inner",
          },
        },
      },
    }
  end,
}
