{pkgs, ...}: {
  programs.tmux.enable = true;
  programs.tmux.clock24 = true;
  programs.tmux.plugins = with pkgs.tmuxPlugins; [
    better-mouse-mode
    gruvbox
    resurrect
    sensible
    vim-tmux-navigator
    yank
    {
      plugin = rose-pine;
      extraConfig = ''
        unbind C-b

        set -g prefix C-Space
        set -g mouse on

        set-option -g status-position top

        bind C-Space send-prefix
        bind - split-window -h
        bind '=' split-window -v

        bind-key h select-pane -L
        bind-key j select-pane -D
        bind-key k select-pane -U
        bind-key l select-pane -R
      '';
    }
  ];
}
