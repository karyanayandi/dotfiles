{
  lib,
  pkgs,
  ...
}: {
  stylix = {
    enable = true;
    image = ../../wallpapers/onedark/od_outrun_wave.png;
    override = {
      base00 = "#282c34";
      base01 = "#353b45";
      base02 = "#3e4451";
      base03 = "#545862";
      base04 = "#565c64";
      base05 = "#abb2bf";
      base06 = "#b6bdca";
      base07 = "#c8ccd4";
      base08 = "#D57780";
      base09 = "#d19a66";
      base0A = "#e5c07b";
      base0B = "#98c379";
      base0C = "#88C0D0";
      base0D = "#81A1C1";
      base0E = "#B988B0";
      base0F = "#D08F70";
    };
    fonts = {
      sizes = {
        applications = 10;
        desktop = 10;
        popups = 10;
        terminal = 13;
      };
      serif = {
        package = pkgs.noto-fonts;
        name = "Noto Serif";
      };
      sansSerif = {
        package = pkgs.inter;
        name = "Inter Variable";
      };
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetbrainsMono NF";
      };
      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };
    };
    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 24;
    };
    targets = {
      chromium.enable = lib.mkForce false;
    };
  };
}
