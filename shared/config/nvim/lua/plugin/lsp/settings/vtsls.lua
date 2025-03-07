return {
  settings = {
    tsserver = {
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
    typescript = {
      inlayHints = {
        parameterNames = { enabled = "literals" },
        parameterTypes = { enabled = true },
        variableTypes = { enabled = true },
        propertyDeclarationTypes = { enabled = true },
        functionLikeReturnTypes = { enabled = true },
        enumMemberValues = { enabled = true },
      },
    },
  },
}
