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
in {
  home.packages = [
    screenRecordScript
    stopScreenRecordScript
  ];

  home.sessionVariables = {
    PATH = "${config.home.homeDirectory}/.local/share/bin:${pkgs.coreutils}/bin";
  };
}
