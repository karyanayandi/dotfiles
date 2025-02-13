{
  config,
  pkgs,
  ...
}: let
  nodeJsConfig = ''
    export PATH=${pkgs.nodejs}/bin:$PATH
    export NODE_OPTIONS=--max_old_space_size=4096
    npm config set prefix "${config.home.homeDirectory}/.cache/npm/global"
    mkdir -p "${config.home.homeDirectory}/.cache/npm/global"
  '';
in {
  home.activation.configureNode = ''
    ${nodeJsConfig}
  '';

  home.sessionVariables = {
    NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.cache/npm/global";
  };

  home.packages = with pkgs; [
    beekeeper-studio
    bun
    cargo
    clippy
    corepack_23
    deno
    gcc
    go
    lua
    nixpacks
    node-gyp
    nodePackages.vercel
    nodejs_23
    pnpm
    rustc
    # Formatters and Linters
    alejandra
    eslint_d
    gofumpt
    goimports-reviser
    golangci-lint
    golines
    jq
    luajitPackages.luacheck
    luajitPackages.luarocks
    nodePackages.jsonlint
    prettierd
    stylua
  ];
}
