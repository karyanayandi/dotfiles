return {
  "yetone/avante.nvim",
  lazy = false,
  version = "*",
  build = "make",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "MeanderingProgrammer/render-markdown.nvim",
    --- Optional dependencies
    "nvim-telescope/telescope.nvim",
    "hrsh7th/nvim-cmp",
    "nvim-tree/nvim-web-devicons",
    "zbirenbaum/copilot.lua",
    {
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
          use_absolute_path = true,
        },
      },
    },
  },
  opts = {
    provider = "copilot",
    copilot = {
      endpoint = "https://api.githubcopilot.com",
      model = "claude-3.7-sonnet",
      proxy = nil,
      allow_insecure = true,
      timeout = 30000,
      temperature = 0,
      max_tokens = 8192,
      disable_tools = false,
    },
    mappings = {
      diff = {
        ours = "co",
        theirs = "ct",
        all_theirs = "cy",
        both = "cb",
        cursor = "cc",
        next = "]x",
        prev = "[x",
      },
      suggestion = {
        accept = "<M-l>",
        next = "<M-]>",
        prev = "<M-[>",
        dismiss = "<C-]>",
      },
      jump = {
        next = "]]",
        prev = "[[",
      },
      submit = {
        normal = "<CR>",
        insert = "<C-S>",
      },
      sidebar = {
        apply_all = "A",
        apply_cursor = "y",
        switch_windows = "<Tab>",
        reverse_switch_windows = "<S-Tab>",
      },
    },
    hints = { enabled = true },
    windows = {
      ---@type "right" | "left" | "top" | "bottom"
      position = "right",
      wrap = true,
      width = 30,
      sidebar_header = {
        enabled = true,
        align = "left",
        rounded = false,
      },
      input = {
        prefix = "> ",
        height = 8,
      },
      edit = {
        border = "thin",
        start_insert = true,
      },
      ask = {
        floating = false,
        start_insert = true,
        border = "thin",
        ---@type "ours" | "theirs"
        focus_on_apply = "ours",
      },
    },
    highlights = {
      ---@type AvanteConflictHighlights
      diff = {
        current = "DiffText",
        incoming = "DiffAdd",
      },
    },
    --- @class AvanteConflictUserConfig
    diff = {
      autojump = true,
      ---@type string | fun(): any
      list_opener = "copen",
      override_timeoutlen = 500,
    },
    suggestion = {
      debounce = 600,
      throttle = 600,
    },
    web_search_engine = {
      provider = "google",
    },
  },
}
