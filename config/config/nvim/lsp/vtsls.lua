return {
  settings = {
    tsserver = {
      -- globalPlugins = {
      --   {
      --     name = "@vue/typescript-plugin",
      --     location = require("mason-registry").get_package("vue-language-server"):get_install_path()
      --       .. "/node_modules/@vue/language-server",
      --     languages = { "vue" },
      --     configNamespace = "typescript",
      --     enableForWorkspaceTypeScriptVersions = true,
      --   },
      --   {
      --     name = "@astrojs/ts-plugin",
      --     location = require("mason-registry").get_package("astro-language-server"):get_install_path()
      --       .. "/node_modules/@astrojs/language-server",
      --     languages = { "astro" },
      --     configNamespace = "typescript",
      --     enableForWorkspaceTypeScriptVersions = true,
      --   },
      --   {
      --     name = "typescript-svelte-plugin",
      --     location = require("mason-registry").get_package("svelte-language-server"):get_install_path()
      --       .. "/node_modules/svelte-language-server",
      --     languages = { "svelte" },
      --     configNamespace = "typescript",
      --     enableForWorkspaceTypeScriptVersions = true,
      --   },
      -- },
    },
    typescript = {
      inlayHints = {
        includeInlayParameterNameHints = "all",
        includeInlayParameterNameHintsWhenArgumentMatchesName = true,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayVariableTypeHintsWhenTypeMatchesName = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
      },
    },
    javascript = {
      inlayHints = {
        includeInlayParameterNameHints = "all",
        includeInlayParameterNameHintsWhenArgumentMatchesName = true,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayVariableTypeHintsWhenTypeMatchesName = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
      },
    },
  },
}
