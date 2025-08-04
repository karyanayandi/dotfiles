-- luacheck: globals vim
-- luacheck: ignore 631

local fmt = string.format
local git_diff = vim.fn.system("git diff --no-ext-diff --staged"):gsub("%s+$", "")

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
    prompt_library = {
      ["Generate a Commit Message"] = {
        strategy = "inline",
        description = "Generate a commit message (custom)",
        opts = {
          adapter = {
            name = "copilot",
            model = "gpt-4.1",
          },
          index = 9,
          is_default = true,
          is_slash_cmd = true,
          short_name = "generate_commit",
          auto_submit = true,
        },
        prompts = {
          {
            role = "user",
            content = fmt(
              "You are an expert at following the commitizen convention, keep the title under 50 characters and wrap message at 72 characters. Given the git diff listed below, please generate a commit message for me:\n\n```diff\n%s\n```\n",
              git_diff
            ),
          },
        },
      },
    },
    strategies = {
      chat = {
        adapter = {
          name = "copilot",
          -- model = "claude-3.7-sonnet",
          model = "gpt-4.1",
        },
        variables = {
          ["buffer"] = {
            opts = {
              default_params = "pin",
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
          close = {
            modes = { n = { "<C-c>", "<Esc>" }, i = "<C-c>" },
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
      "<leader>aq",
      function()
        vim.ui.input({
          prompt = "Question: ",
          default = "'<,'>CodeCompanion ",
        }, function(input)
          if input and input ~= "" then
            vim.cmd(input)
          end
        end)
      end,
      desc = "Ask a question",
      mode = { "v" },
    },
    {
      "<leader>ag",
      "<cmd>CodeCompanion /generate_commit<CR>",
      desc = "Generate commit message",
      mode = { "n", "v" },
    },
  },
}
