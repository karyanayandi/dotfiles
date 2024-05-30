{pkgs, ...}: let
  nodeJsConfig = ''
    npm config set prefix "${HOME}/.cache/npm/global"
    mkdir -p "${HOME}/.cache/npm/global"
    npm install -g ls_emmet @vtsls/language-server
  '';
in {
  home.file.".npmrc".text = "prefix=${HOME}/.cache/npm/global";

  home.activation = {
    configureNode = {
      script = nodeJsConfig;
      after = ["linkGeneration"];
    };
  };
}
