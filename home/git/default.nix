{
  programs.git = {
    enable = true;
    userName = "karyanaayandi";
    userEmail = "xkaryanayandi@gmail.com";
    extraConfig = {
      credential.helper = "cache --timeout=18000";
      core.editor = "nvim";
      core.ignoreCase = false;
      init.defaultBranch = "main";
      push.default = "simple";
    };
  };

  programs.gh.enable = true;
  programs.gitui.enable = true;
}
