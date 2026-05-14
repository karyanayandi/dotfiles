-- luacheck: globals vim

return {
  "nvim-treesitter/nvim-treesitter",
  version = false,
  lazy = vim.fn.argc(-1) == 0,
  event = { "BufReadPost", "BufNewFile" },
  build = ":TSUpdate",
  cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
  dependencies = {
    {
      "JoosepAlviste/nvim-ts-context-commentstring",
      lazy = true,
      config = function()
        require("ts_context_commentstring").setup {}
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
          disable_filetype = { "TelescopePrompt", "fzf", "spectre_panel", "snacks_dashboard", "snacks_terminal" },
          ignored_next_char = string.gsub([[ [%w%%%'%[%"%.] ]], "%s+", ""),
          enable_moveright = true,
          disable_in_macro = false,
          enable_afterquote = true,
          map_bs = true,
          map_c_w = false,
          disable_in_visualblock = false,
          fast_wrap = {
            map = "<M-e>",
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
    -- local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
    -- parser_config.astro = {
    --   install_info = {
    --     url = "https://github.com/virchau13/tree-sitter-astro",
    --     files = { "src/parser.c" },
    --     branch = "main",
    --   },
    --   filetype = "astro",
    -- }
    --
    -- vim.filetype.add {
    --   extension = {
    --     astro = "astro",
    --   },
    -- }
    --
    -- vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
    --   pattern = "*.astro",
    --   callback = function(ev)
    --     if vim.bo[ev.buf].filetype == "astro" then
    --       vim.cmd "TSEnable highlight"
    --     end
    --   end,
    --   group = vim.api.nvim_create_augroup("AstroTreesitter", { clear = true }),
    -- })

    require("nvim-treesitter").setup {}

    -- Highlight is built into Neovim 0.10+ via treesitter, no config needed.

    -- Install parsers (non-blocking, avoids slowing down startup)
    local ensure_installed = {
      "astro",
      "bash",
      "c",
      "css",
      "diff",
      "gitcommit",
      "go",
      "html",
      "javascript",
      "jsdoc",
      "json",
      "jsonc",
      "lua",
      "luadoc",
      "luap",
      "markdown",
      "markdown_inline",
      "nix",
      "php",
      "printf",
      "python",
      "query",
      "regex",
      "rust",
      "svelte",
      "toml",
      "tsx",
      "typescript",
      "vim",
      "vimdoc",
      "vue",
      "xml",
      "yaml",
    }
    vim.defer_fn(function()
      pcall(require("nvim-treesitter").install, ensure_installed)
    end, 0)

    -- Treesitter-based indentation
    vim.opt.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "python",
      callback = function()
        vim.bo.indentexpr = ""
      end,
    })

    -- Textobjects: configure plugin and set keymaps
    require("nvim-treesitter-textobjects").setup {
      select = {
        lookahead = true,
      },
    }
    local select = require("nvim-treesitter-textobjects.select")
    local textobjects = {
      af = "@function.outer",
      ["if"] = "@function.inner",
      at = "@class.outer",
      it = "@class.inner",
      ac = "@call.outer",
      ic = "@call.inner",
      aa = "@parameter.outer",
      ia = "@parameter.inner",
      al = "@loop.outer",
      il = "@loop.inner",
      ai = "@conditional.outer",
      ii = "@conditional.inner",
      ["a/"] = "@comment.outer",
      ["i/"] = "@comment.inner",
      ab = "@block.outer",
      ib = "@block.inner",
      as = "@statement.outer",
      is = "@scopename.inner",
      aA = "@attribute.outer",
      iA = "@attribute.inner",
      aF = "@frame.outer",
      iF = "@frame.inner",
    }
    for key, query in pairs(textobjects) do
      vim.keymap.set({ "o", "x" }, key, function()
        select.select_textobject(query)
      end, { desc = query })
    end

    -- Incremental selection (Neovim built-in since 0.9)
    vim.keymap.set("n", "<C-space>", function()
      vim.treesitter.incremental_selection()
    end, { desc = "Incremental selection" })
    vim.keymap.set("n", "<bs>", function()
      vim.treesitter.incremental_selection("decrement")
    end, { desc = "Decrement selection" })
  end,
}
