{pkgs, ...}: {
  programs.alacritty = {
    enable = true;
    settings = {
      window.padding = {
        x = 2;
        y = 2;
      };
      cursor.style = "Beam";
      terminal.shell = "${pkgs.fish}/bin/fish";
    };
  };
}
