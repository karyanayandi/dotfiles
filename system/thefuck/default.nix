{pkgs, ...}: {
  programs.thefuck = {
    enable = true;
    alias = "fuck";
    enableFishIntegration = true;
    enableBashIntegration = true;
  };
}
