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
  programs.gitui = {
    enable = true;
    keyConfig = ''
      move_left: Some(( code: Char('h'), modifiers: "")),
      move_right: Some(( code: Char('l'), modifiers: "")),
      move_up: Some(( code: Char('k'), modifiers: "")),
      move_down: Some(( code: Char('j'), modifiers: "")),
      stage_unstage_item: Some(( code: Char('Space'), modifiers: "")),
    '';
  };
}
