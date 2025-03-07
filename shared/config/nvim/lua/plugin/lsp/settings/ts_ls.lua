-- TODO: dont run ts_ls when there is deno.json or deno.jsonc file

-- luacheck: globals vim

return {
  default_config = {
    filetypes = {
      "javascript",
      "typescript",
      "astro",
      "svelte",
      "vue",
    },
  },
  init_options = {
    globalPlugins = {
      {
        name = "@vue/typescript-plugin",
        location = require("mason-registry").get_package("vue-language-server"):get_install_path()
          .. "/node_modules/@vue/language-server",
        languages = { "vue" },
        configNamespace = "typescript",
        enableForWorkspaceTypeScriptVersions = true,
      },
      {
        name = "@astrojs/ts-plugin",
        location = require("mason-registry").get_package("astro-language-server"):get_install_path()
          .. "/node_modules/@astrojs/language-server",
        languages = { "astro" },
        configNamespace = "typescript",
        enableForWorkspaceTypeScriptVersions = true,
      },
    },
  },
  settings = {
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
