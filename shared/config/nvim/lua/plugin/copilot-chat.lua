-- luacheck: globals vim
-- luacheck: ignore 631

return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    event = "VeryLazy",
    version = "*",
    -- commit = "7e6583c75f1231ea1eac70e06995dd3f97a58478",
    dependencies = {
      { "zbirenbaum/copilot.lua" },
      { "nvim-lua/plenary.nvim" },
    },
    build = "make tiktoken",
    config = function()
      vim.g.copilot_no_tab_map = true
      vim.g.copilot_hide_during_completion = 0
      vim.g.copilot_proxy_strict_ssl = 0

      local chat = require "CopilotChat"
      local actions = require "CopilotChat.actions"
      local select = require "CopilotChat.select"

      chat.setup {
        agent = "copilot",
        model = "claude-3.7-sonnet",
        -- model = "gpt-4",
        debug = false,
        allow_insecure = true,
        selection = function(source)
          return select.visual(source) or select.buffer(source)
        end,
        sticky = {
          "/COPILOT_GENERATE",
          "#buffers",
        },
        prompts = {
          Explain = {
            mapping = "<leader>ae",
            description = "Explain",
          },
          Review = {
            mapping = "<leader>ar",
            description = "Review",
          },
          Tests = {
            mapping = "<leader>at",
            description = "Tests",
          },
          Fix = {
            mapping = "<leader>af",
            description = "Fix",
          },
          Optimize = {
            mapping = "<leader>ao",
            description = "Optimize",
          },
          Docs = {
            mapping = "<leader>ad",
            description = "Documentation",
          },
          Commit = {
            mapping = "<leader>ag",
            description = "Generate Commit",
            selection = select.buffer,
          },
          Refactor = {
            prompt = "> /COPILOT_GENERATE\n\nPlease refactor the following code to improve its clarity and readability.",
            mapping = "<leader>aR",
            description = "Refactor",
          },
          BetterNamings = {
            prompt = "> /COPILOT_GENERATE\n\nPlease provide better names for the following variables and functions.",
            mapping = "<leader>ab",
            description = "Better Naming",
          },
          -- Summarize = {
          --   prompt = "Please summarize the following text.",
          --   mapping = "<leader>as",
          --   description = "Summarize",
          -- },
          -- Spelling = {
          --   prompt = "Please correct any grammar and spelling errors in the following text.",
          --   mapping = "<leader>aS",
          --   description = "Spelling",
          -- },
          -- Wording = {
          --   prompt = "Please improve the grammar and wording of the following text.",
          --   mapping = "<leader>aw",
          --   description = "Wording",
          -- },
          -- Concise = {
          --   prompt = "Please rewrite the following text to make it more concise.",
          --   mapping = "<leader>aC",
          --   description = "Concise",
          -- },
          -- SwaggerApiDocs = {
          --   prompt = "Please provide documentation for the following API using Swagger.",
          --   mapping = "<leader>az",
          --   description = "Swagger Api Docs",
          -- },
          -- SwaggerJsDocs = {
          --   prompt = "Please write JSDoc for the following API using Swagger.",
          --   mapping = "<leader>aZ",
          --   description = "Swagger JS Docs",
          -- },
        },
        providers = {
          github_models = {
            disabled = false,
          },
        },
        window = {
          layout = "vertical",
          width = 0.5,
          height = 0.5,
          relative = "editor",
          border = "single",
          row = nil,
          col = nil,
          title = "Copilot Chat",
          footer = nil,
          zindex = 1,
        },
        show_help = true,
        show_folds = true,
        highlight_selection = true,
        highlight_headers = false,
        auto_follow_cursor = true,
        auto_insert_mode = false,
        insert_at_end = false,
        clear_chat_on_new_prompt = false,
        question_header = "[!HELP] User ",
        answer_header = "[!SUMMARY] Copilot ",
        error_header = "[!ERROR] Error",
        separator = "",
        mappings = {
          complete = {
            detail = "Use @<Tab> or /<Tab> for options.",
            insert = "<Tab>",
          },
          close = {
            normal = "q",
            insert = "<C-c>",
          },
          reset = {
            normal = "<C-x>",
            insert = "<C-x>",
          },
          submit_prompt = {
            normal = "<CR>",
            insert = "<C-s>",
          },
          toggle_sticky = {
            detail = "Makes line under cursor sticky or deletes sticky line.",
            normal = "gr",
          },
          accept_diff = {
            normal = "<C-y>",
            insert = "<C-y>",
          },
          jump_to_diff = {
            normal = "gj",
          },
          quickfix_answers = {
            normal = "gqa",
          },
          quickfix_diffs = {
            normal = "gqd",
          },
          yank_diff = {
            normal = "gy",
            register = '"',
          },
          show_diff = {
            normal = "gd",
            full_diff = true,
          },
          show_info = {
            normal = "gi",
          },
          show_context = {
            normal = "gc",
          },
          show_help = {
            normal = false,
          },
        },
      }

      vim.keymap.set({ "n" }, "<leader>ap", function()
        require("CopilotChat.integrations.telescope").pick(actions.prompt_actions {
          context = { "buffers", "files" },
        })
      end, { desc = "Prompts" })

      vim.keymap.set({ "v" }, "<leader>ap", function()
        require("CopilotChat.integrations.telescope").pick(actions.prompt_actions {
          selection = select.visual,
        })
      end, { desc = "Prompts" })

      vim.keymap.set({ "n" }, "<leader>aq", function()
        vim.ui.input({
          prompt = "Question: ",
        }, function(input)
          if input and input ~= "" then
            chat.ask(input, {
              context = { "buffers", "files" },
            })
          end
        end)
      end, { desc = "Question" })

      vim.keymap.set({ "v" }, "<leader>aq", function()
        vim.ui.input({
          prompt = "Question: ",
        }, function(input)
          if input and input ~= "" then
            chat.ask(input, {
              selection = select.visual,
            })
          end
        end)
      end, { desc = "Question" })

      vim.keymap.set({ "n" }, "<leader>as", function()
        vim.ui.input({
          prompt = "Save as: ",
        }, function(input)
          if input and input ~= "" then
            chat.save(input)
          end
        end)
      end, { desc = "Save Chat" })

      vim.keymap.set({ "n" }, "<leader>al", function()
        vim.ui.input({
          prompt = "Chat name: ",
        }, function(input)
          if input and input ~= "" then
            chat.load(input)
          end
        end)
      end, { desc = "Load Chat" })
    end,
  },
}
