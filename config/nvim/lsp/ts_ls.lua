-- TODO: dont run ts_ls when there is deno.json or deno.jsonc file

-- luacheck: globals vim

local globalPlugins = {}

-- Vue plugin
local vue_path = vim.fn.expand "$MASON/packages/vue-language-server/node_modules/@vue/language-server"
if vue_path then
  table.insert(globalPlugins, {
    name = "@vue/typescript-plugin",
    location = vue_path,
    languages = { "vue" },
    configNamespace = "typescript",
    enableForWorkspaceTypeScriptVersions = true,
  })
end

-- Astro plugin
local astro_path = vim.fn.expand "$MASON/packages/astro-language-server/node_modules/@astrojs/language-server"
if astro_path then
  table.insert(globalPlugins, {
    name = "@astrojs/ts-plugin",
    location = astro_path,
    languages = { "astro" },
    configNamespace = "typescript",
    enableForWorkspaceTypeScriptVersions = true,
  })
end

-- Svelte plugin
local svelte_path = vim.fn.expand "$MASON/packages/svelte-language-server/node_modules/svelte-language-server"
if svelte_path then
  table.insert(globalPlugins, {
    name = "typescript-svelte-plugin",
    location = svelte_path,
    languages = { "svelte" },
    configNamespace = "typescript",
    enableForWorkspaceTypeScriptVersions = true,
  })
end

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
    globalPlugins = globalPlugins,
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
