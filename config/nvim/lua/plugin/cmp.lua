-- luacheck: globals vim

return {
  "saghen/blink.cmp",
  dependencies = {
    "MahanRahmati/blink-nerdfont.nvim",
    "mikavilpas/blink-ripgrep.nvim",
    "moyiz/blink-emoji.nvim",
    {
      "saghen/blink.compat",
      version = "*",
      lazy = true,
      opts = {},
    },
    {
      "fang2hou/blink-copilot",
      dependencies = "zbirenbaum/copilot.lua",
    },
  },
  event = { "InsertEnter", "CmdlineEnter" },
  version = "*",
  opts = {
    keymap = {
      preset = "none",
      ["<C-k>"] = { "select_prev", "fallback" },
      ["<C-j>"] = { "select_next", "fallback" },
      ["<C-p>"] = { "select_prev", "fallback" },
      ["<C-n>"] = { "select_next", "fallback" },
      ["<Up>"] = { "select_prev", "fallback" },
      ["<Down>"] = { "select_next", "fallback" },
      ["<C-h>"] = {
        function(cmp)
          cmp.show_documentation()
        end,
        "fallback",
      },
      ["<C-b>"] = { "scroll_documentation_up", "fallback" },
      ["<C-f>"] = { "scroll_documentation_down", "fallback" },
      ["<C-Space>"] = { "show", "fallback" },
      ["<C-e>"] = { "cancel", "fallback" },
      ["<CR>"] = { "accept", "fallback" },
      ["<Tab>"] = {
        function(cmp)
          if cmp.snippet_active() then
            return cmp.accept()
          else
            return cmp.select_next()
          end
        end,
        "snippet_forward",
        "fallback",
      },
      ["<S-Tab>"] = {
        function(cmp)
          if cmp.snippet_active() then
            return cmp.accept()
          else
            return cmp.select_prev()
          end
        end,
        "snippet_backward",
        "fallback",
      },
    },
    appearance = {
      use_nvim_cmp_as_default = false,
      nerd_font_variant = "mono",
      kind_icons = {
        Class = " ",
        Color = " ",
        Constant = " ",
        Constructor = " ",
        Copilot = " ",
        Enum = " ",
        EnumMember = " ",
        Event = " ",
        Field = " ",
        File = " ",
        Folder = " ",
        Function = "󰊕",
        Interface = " ",
        Keyword = " ",
        Method = " ",
        Misc = " ",
        Module = " ",
        Operator = " ",
        Property = " ",
        Reference = " ",
        Snippet = " ",
        Struct = " ",
        Text = " ",
        TypeParameter = " ",
        Unit = " ",
        Value = " ",
        Variable = " ",
      },
    },
    completion = {
      ghost_text = { enabled = true },
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 200,
        update_delay_ms = 50,
        window = {
          winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,EndOfBuffer:BlinkCmpDoc",
        },
      },
      list = {
        max_items = 200,
        selection = {
          preselect = true,
          auto_insert = false,
        },
      },
      menu = {
        draw = {
          align_to = "label",
          columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind" } },
          components = {
            kind_icon = {
              text = function(ctx)
                local icons = require "config.icons"
                -- Special handling for Copilot
                if ctx.source_name == "copilot" then
                  return icons.git.Octoface
                end
                -- Special handling for ripgrep
                if ctx.source_name == "Ripgrep" then
                  return icons.ui.Lightbulb
                end
                -- Special handling for nerd font
                if ctx.source_name == "Nerd Fonts" then
                  return icons.misc.Text
                end
                -- Special handling for emoji
                if ctx.source_name == "emoji" then
                  return icons.misc.Smiley
                end
                -- Use the icon from blink's kind_icons or fallback
                return ctx.kind_icon
              end,
              highlight = function(ctx)
                -- Special highlight for Copilot
                if ctx.source_name == "copilot" then
                  return "BlinkCmpItemKindCopilot"
                end
                -- Special highlight for emoji
                if ctx.source_name == "emoji" then
                  return "BlinkCmpItemKindEmoji"
                end
                -- Special highlight for emoji
                if ctx.source_name == "Nerd Fonts" then
                  return "BlinkCmpItemKindNerdFonts"
                end
                -- Default highlight
                return "BlinkCmpKind" .. ctx.kind
              end,
            },
          },
        },
      },
    },
    sources = {
      default = {
        "lsp",
        "path",
        "snippets",
        "buffer",
        "ripgrep",
        "markdown",
        "copilot",
        "nerdfont",
        "emoji",
      },
      providers = {
        lsp = {
          name = "LSP",
          module = "blink.cmp.sources.lsp",
          score_offset = 100,
          -- Filter out Text items in non-markdown files
          transform_items = function(_ctx, items)
            local kind = require("blink.cmp.types").CompletionItemKind
            if vim.bo.filetype ~= "markdown" then
              items = vim.tbl_filter(function(item)
                return item.kind ~= kind.Text
              end, items)
            end
            return items
          end,
        },
        ripgrep = {
          module = "blink-ripgrep",
          name = "Ripgrep",
          opts = {},
        },
        markdown = {
          name = "RenderMarkdown",
          module = "render-markdown.integ.blink",
          fallbacks = { "lsp" },
        },
        path = {
          name = "Path",
          module = "blink.cmp.sources.path",
          score_offset = 30,
          opts = {
            trailing_slash = false,
            label_trailing_slash = true,
          },
        },
        buffer = {
          name = "Buffer",
          module = "blink.cmp.sources.buffer",
          score_offset = 40,
        },
        copilot = {
          name = "copilot",
          module = "blink-copilot",
          score_offset = 100,
          async = true,
          opts = {},
        },
        nerdfont = {
          name = "Nerd Fonts",
          module = "blink-nerdfont",
          score_offset = 15,
          opts = {
            insert = true,
            trigger = ":",
          },
        },
        emoji = {
          name = "emoji",
          module = "blink-emoji",
          score_offset = 15,
          opts = {
            insert = true,
            trigger = ":",
          },
        },
        -- snippets = {
        --   name = "Snippets",
        --   module = "blink.cmp.sources.snippets",
        --   score_offset = 50,
        -- },
        snippets = {
          opts = {
            friendly_snippets = true,
          },
        },
      },
    },
    signature = { enabled = true },
    fuzzy = {
      implementation = "prefer_rust",
    },
    cmdline = {
      enabled = true,
      completion = { ghost_text = { enabled = false } },
      sources = function()
        local type = vim.fn.getcmdtype()
        if type == "/" or type == "?" then
          return { "buffer" }
        end
        if type == ":" or type == "@" then
          return { "cmdline", "path" }
        end
        return {}
      end,
    },
  },
  config = function(_, opts)
    local colors = require("base16-colorscheme").colors

    -- Set up highlight groups
    vim.api.nvim_set_hl(0, "BlinkCmpDoc", { bg = colors.base02, fg = colors.base05 })
    vim.api.nvim_set_hl(0, "BlinkCmpDocBorder", { bg = colors.base02, fg = colors.base05 })
    vim.api.nvim_set_hl(0, "BlinkCmpDocSeparator", { bg = colors.base02, fg = colors.base05 })

    vim.api.nvim_set_hl(0, "BlinkCmpItemKindCopilot", { fg = colors.base0E })
    vim.api.nvim_set_hl(0, "BlinkCmpKindRipgrep", { fg = colors.base0F })
    vim.api.nvim_set_hl(0, "BlinkCmpItemKindEmoji", { fg = colors.base0C })
    vim.api.nvim_set_hl(0, "BlinkCmpItemKindNerdFonts", { fg = colors.base0A })

    require("blink.cmp").setup(opts)
  end,
}
