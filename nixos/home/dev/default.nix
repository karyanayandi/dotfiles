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
    npm install -g corepack
  '';
in {
  home.activation.configureNode = ''
    ${nodeJsConfig}
  '';

  home.packages = with pkgs; [
    beekeeper-studio
    bun
    cargo
    clippy
    deno
    gcc
    go
    lua
    nixpacks
    node-gyp
    nodePackages.vercel
    nodejs
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
