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
    npm install -g node-gyp ls_emmet @dokploy/cli vercel
  '';
in {
  home.activation.configureNode = ''
    ${nodeJsConfig}
  '';

  home.sessionVariables = {
    NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.cache/npm/global";
  };

  home.packages = with pkgs; [
    bun
    cargo
    clippy
    corepack
    gcc
    go
    jetbrains.datagrip
    nixpacks
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
    prettierd
    shellcheck
    stylua
  ];
}
