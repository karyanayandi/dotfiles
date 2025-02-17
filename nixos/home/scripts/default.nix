{
  config,
  pkgs,
  lib,
  ...
}: let
  screenRecordScript = pkgs.writeShellScriptBin "screen-record" ''
    ${builtins.readFile ../../../shared/local/bin/screen-record.sh}
  '';

  stopScreenRecordScript = pkgs.writeShellScriptBin "stop-screen-record" ''
    ${builtins.readFile ../../../shared/local/bin/stop-screen-record.sh}
  '';

  powerMenuScript = pkgs.writeShellScriptBin "power-menu" ''
    ${builtins.readFile ./power-menu.sh}
  '';
in {
  home.packages = [
    screenRecordScript
    stopScreenRecordScript
    powerMenuScript
  ];

  home.sessionVariables = {
    PATH = "${config.home.homeDirectory}/.local/share/bin:${pkgs.coreutils}/bin";
    QT_QPA_PLATFORMTHEME = lib.mkForce "gtk3";
  };
}
