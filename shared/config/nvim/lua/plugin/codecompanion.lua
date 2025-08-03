return {
  "olimorris/codecompanion.nvim",
  cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
  dependencies = {
    "ravitemer/mcphub.nvim",
    {
      "echasnovski/mini.diff",
      config = function()
        local diff = require "mini.diff"
        diff.setup {
          source = diff.gen_source.none(),
        }
      end,
    },
    {
      "HakonHarnes/img-clip.nvim",
      opts = {
        filetypes = {
          codecompanion = {
            prompt_for_file_name = false,
            template = "[Image]($FILE_PATH)",
            use_absolute_path = true,
          },
        },
      },
    },
  },
  opts = {
    strategies = {
      chat = {
        adapter = {
          name = "copilot",
          model = "gpt-4.1",
        },
        roles = {
          user = "user",
        },
        keymaps = {
          send = {
            modes = {
              i = { "<C-CR>", "<C-s>" },
            },
          },
          completion = {
            modes = {
              i = "<C-x>",
            },
          },
        },
        slash_commands = {
          ["buffer"] = {
            keymaps = {
              modes = {
                i = "<C-b>",
              },
            },
          },
          ["fetch"] = {
            keymaps = {
              modes = {
                i = "<C-f>",
              },
            },
          },
          ["help"] = {
            opts = {
              max_lines = 1000,
            },
          },
          ["image"] = {
            keymaps = {
              modes = {
                i = "<C-i>",
              },
            },
            opts = {
              dirs = { "~/Pictures/Screenshots" },
            },
          },
        },
      },
      inline = {
        adapter = {
          name = "copilot",
          model = "gpt-4.1",
        },
      },
    },
    display = {
      action_palette = {
        provider = "default",
      },
      chat = {
        show_references = true,
        show_header_separator = true,
        show_settings = false,
        icons = {
          tool_success = "󰸞",
        },
      },
      diff = {
        provider = "mini_diff",
      },
    },
    opts = {
      log_level = "DEBUG",
    },
  },
  extensions = {
    mcphub = {
      callback = "mcphub.extensions.codecompanion",
      opts = {
        make_vars = true,
        make_slash_commands = true,
        show_result_in_chat = true,
      },
    },
  },
  keys = {
    {
      "<leader>aa",
      "<cmd>CodeCompanionChat Toggle<CR>",
      desc = "Toggle a chat buffer",
      mode = { "n", "v" },
    },
    {
      "<leader>aq",
      "<cmd>CodeCompanionActions<CR>",
      desc = "Open the action palette",
      mode = { "n", "v" },
    },
    {
      "<M-q>",
      "<cmd>CodeCompanionActions<CR>",
      desc = "Open the action palette",
      mode = { "n", "v" },
    },
    {
      "<leader>ap",
      "<cmd>CodeCompanionChat Add<CR>",
      desc = "Add code to a chat buffer",
      mode = { "v" },
    },
    {
      "<leader>ae",
      "<cmd>CodeCompanion /explain<CR>",
      desc = "Explain code",
      mode = { "n", "v" },
    },
    {
      "<leader>af",
      "<cmd>CodeCompanion /fix<CR>",
      desc = "Fix code",
      mode = { "n", "v" },
    },
    {
      "<leader>ag",
      "<cmd>CodeCompanion /commit<CR>",
      desc = "Generate commit message",
      mode = { "n", "v" },
    },
    {
      "<leader>at",
      "<cmd>CodeCompanion /tests<CR>",
      desc = "Generate unit tests",
      mode = { "n", "v" },
    },
  },
}
