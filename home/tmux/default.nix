{pkgs, ...}: {
  programs.tmux.enable = true;
  programs.tmux.clock24 = true;
  programs.tmux.plugins = with pkgs.tmuxPlugins; [
    gruvbox
    sensible
    yank
    resurrect
    better-mouse-mode
    {
      plugin = rose-pine;
      extraConfig = ''
        unbind C-b
        set -g prefix C-Space
        bind C-Space send-prefix
        set -g mouse on
      '';
    }
  ];
}
