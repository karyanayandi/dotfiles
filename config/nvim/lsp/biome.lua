-- luacheck: globals vim

return {
  root_dir = function(fname)
    local util = require "lspconfig.util"
    return util.root_pattern("biome.json", "biome.jsonc")(fname)
  end,
}
