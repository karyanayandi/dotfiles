{
  config,
  pkgs,
  ...
}: let
  createExecutableScript = {
    name,
    content,
  }:
    pkgs.runCommand name {} ''
      mkdir -p $out/bin
      scriptPath=$out/bin/${name}
      echo "${content}" > ${scriptPath}
      chmod +x ${scriptPath}
    '';

  screenRecordScriptContent = builtins.readFile ./screen-record.sh;
  stopScreenRecordScriptContent = builtins.readFile ./stop-screen-record.sh;

  screenRecordScript = createExecutableScript {
    name = "screen-record";
    content = screenRecordScriptContent;
  };

  stopScreenRecordScript = createExecutableScript {
    name = "stop-screen-record";
    content = stopScreenRecordScriptContent;
  };
in {
  home.packages = with pkgs; [
    screenRecordScript
    stopScreenRecordScript
  ];

  home.sessionVariables = {
    PATH = "${config.home.homeDirectory}/.local/share/bin:$PATH";
  };
}
