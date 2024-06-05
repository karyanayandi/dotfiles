{
  config,
  pkgs,
  ...
}: let
  screenRecordScript = pkgs.writeShellScriptBin "screen-record" ''
    ${builtins.readFile ./screen-record.sh}
  '';

  stopScreenRecordScript = pkgs.writeShellScriptBin "stop-screen-record" ''
    ${builtins.readFile ./stop-screen-record.sh}
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
  };
}
