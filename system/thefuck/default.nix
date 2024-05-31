{pkgs, ...}: {
  programs.thefuck = {
    enable = true;
    alias = "fuck";
  };
}
