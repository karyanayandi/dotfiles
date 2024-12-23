{pkgs, ...}: {
  programs.alacritty = {
    enable = true;
    settings = {
      env.TERM = "xterm-256color";
      window.padding = {
        x = 4;
        y = 4;
      };
      cursor.style = "Beam";
      terminal.shell = "${pkgs.fish}/bin/fish";
    };
  };
}
