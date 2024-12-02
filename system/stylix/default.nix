{
  lib,
  pkgs,
  ...
}: let
  theme = ./aurora.yaml;
  wallpaper-path = ../../wallpapers/onedark/od_tux.png;
in {
  stylix = {
    enable = true;
    image = wallpaper-path;
    base16Scheme = theme;
    fonts = {
      sizes = {
        applications = 10;
        desktop = 10;
        popups = 10;
        terminal = 12;
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
