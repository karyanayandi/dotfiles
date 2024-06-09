{
  config,
  pkgs,
  ...
}: let
  nodeJsConfig = ''
    export PATH=${pkgs.nodejs}/bin:$PATH
    npm config set prefix "${config.home.homeDirectory}/.cache/npm/global"
    mkdir -p "${config.home.homeDirectory}/.cache/npm/global"
    npm install -g ls_emmet
  '';
in {
  home.activation.configureNode = ''
    ${nodeJsConfig}
  '';

  home.sessionVariables = {
    NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.cache/npm/global";
  };

  home.packages = with pkgs; [
    alejandra
    bun
    corepack
    eslint_d
    gcc
    go
    nil
    nodejs
    prettierd
    rustup
  ];
}
