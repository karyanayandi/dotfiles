{
  config,
  pkgs,
  ...
}: {
  gtk = {
    enable = true;
    iconTheme = {
      name = "Tela-nord";
      package = pkgs.tela-icon-theme;
    };
    gtk3 = {
      bookmarks = [
        "file://${config.home.homeDirectory}/Documents"
        "file://${config.home.homeDirectory}/Downloads"
        "file://${config.home.homeDirectory}/Musics"
        "file://${config.home.homeDirectory}/Pictures"
        "file://${config.home.homeDirectory}/Codes"
        "file://${config.home.homeDirectory}/Videos"
      ];
    };
  };
}
