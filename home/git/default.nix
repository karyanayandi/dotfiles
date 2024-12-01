{pkgs, ...}: {
  programs.git = {
    enable = true;
    userName = "karyanayandi";
    userEmail = "karyana@yandi.me";
    extraConfig = {
      credential.helper = "cache --timeout=18000";
      core.editor = "nvim";
      core.ignoreCase = false;
      init.defaultBranch = "main";
      push.default = "simple";
    };
  };

  programs.gh.enable = true;
  home.packages = with pkgs; [
    gh-copilot
    lazygit
  ];
}
