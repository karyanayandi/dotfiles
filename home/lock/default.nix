{
  lib,
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [swayidle];

  settings.lock = {
    enable = true;
    bin = "swaylock";
    idle = lib.concatStringsSep " " [
      "swayidle -w"
      "timeout 450 'swaylock -f'"
      "before-sleep 'swaylock -f'"
    ];
  };

  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;
    settings =
      {
        ignore-empty-password = true;
        indicator = true;
        indicator-idle-visible = true;
        indicator-caps-lock = true;
        indicator-radius = 100;
        indicator-thickness = 16;
        line-uses-inside = true;
        effect-blur = "9x7";
        effect-vignette = "0.85:0.85";
        fade-in = 0.1;
      }
      // lib.optionalAttrs (config.settings.wallpaper.${config.settings.scheme} != null) {
        image = config.settings.wallpaper.${config.settings.scheme};
      };
  };
}
