{
  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    plugins = {
      ouch = ./ouch;
    };
    settings = {
      plugin.prepend_previewers = [
        {
          mime = "application/x-tar*";
          run = "ouch";
        }
        {
          mime = "application/x-bzip2";
          run = "ouch";
        }
        {
          mime = "application/x-7z-compressed";
          run = "ouch";
        }
        {
          mime = "application/x-rar*";
          run = "ouch";
        }
        {
          mime = "application/z-xz";
          run = "ouch";
        }
      ];
    };
    keymap = {
      manager.prepend_keymap = [
        {
          on = [
            "C"
            "z"
          ];
          run = "plugin ouch --args=zip";
          desc = "Compress with ouch to zip";
        }
        {
          on = [
            "C"
            "s"
          ];
          run = "plugin ouch --args=tar.zst";
          desc = "Compress with ouch to zst";
        }
      ];
    };
  };
}
