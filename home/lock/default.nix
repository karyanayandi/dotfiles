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
      color = "2e3440cc";
      font = "Jetbrains Mono";
      indicator = true;
      indicator-radius = 200;
      indicator-thickness = 20;
      line-color = "2e3440";
      ring-color = "81a1c1";
      inside-color = "3b4252";
      key-hl-color = "b48ead";
      separator-color = "4c566a";
      text-color = "d8dee9";
      text-caps-lock-color = "";
      line-ver-color = "2e3440";
      ring-ver-color = "81a1c1";
      inside-ver-color = "3b4252";
      text-ver-color = "d8dee9";
      ring-wrong-color = "bf616a";
      text-wrong-color = "bf616a";
      inside-wrong-color = "3b4252";
      inside-clear-color = "3b4252";
      text-clear-color = "d8dee9";
      ring-clear-color = "81a1c1";
      line-clear-color = "2e3440";
      line-wrong-color = "2e3440";
      bs-hl-color = "bf616a";
      grace = 0;
      grace-no-touch = true;
      datestr = "%a, %B %e";
      timestr = "%I:%M %p";
      fade-in = 0.3;
      ignore-empty-password = true;
    };
  };
}
