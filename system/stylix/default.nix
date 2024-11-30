{
  pkgs,
  lib,
  ...
}: {
  stylix = {
    enable = true;
    image = ../../wallpaper.jpg;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
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
        package = (
          pkgs.nerdfonts.override {
            fonts = [
              "JetBrainsMono"
              "GeistMono"
            ];
          }
        );
        name = "GeistMono NF";
      };
      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };
    };
    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 32;
    };
    icon = {
      name = "Tela-nord";
      package = pkgs.tela-icon-theme;
    };
  };
}
