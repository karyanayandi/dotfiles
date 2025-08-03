-- luacheck: globals vim

return {
  "olimorris/codecompanion.nvim",
  cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
  dependencies = {
    "ravitemer/mcphub.nvim",
    "echasnovski/mini.diff",
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
        variables = {
          ["buffer"] = {
            opts = {
              default_params = "pin",
            },
          },
        },
        prompt_library = {
          ["Generate a Commit Message"] = {
            strategy = "chat",
            description = "Generate a commit message",
            opts = {
              name = "github",
              model = "gpt-4o",
              ignore_system_prompt = true,
              index = 9,
              is_default = true,
              is_slash_cmd = true,
              short_name = "gencommit",
              auto_submit = true,
            },
            prompts = {
              {
                role = "user",
                content = "Write commit message for the change with commitizen convention. Keep the title under 50 characters and wrap message at 72 characters. Format as a gitcommit code block.",
              },
            },
          },
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
        keymaps = {
          accept_change = {
            modes = { n = "ga" },
            description = "Accept the suggested change",
          },
          reject_change = {
            modes = { n = "gr" },
            opts = { nowait = true },
            description = "Reject the suggested change",
          },
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
      "<cmd>CodeCompanion /gencommit<CR>",
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
