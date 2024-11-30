{
  lib,
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [swayidle];

  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;
    settings = {
      daemonize = true;
      show-failed-attempts = true;
      clock = true;
      screenshot = true;
      effect-blur = "15x15";
      effect-vignette = "1:1";
      indicator = true;
      indicator-radius = 200;
      indicator-thickness = 20;
      grace = 0;
      grace-no-touch = true;
      datestr = "%a, %B %e";
      timestr = "%I:%M %p";
      fade-in = 0.3;
      ignore-empty-password = true;
    };
  };
}
