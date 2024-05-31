{pkgs, ...}: let
  gruvbox = pkgs.fetchFromGitHub {
    owner = "z3z1ma";
    repo = "tmux-gruvbox";
    rev = "main";
    sha256 = "0kaspb4zk79bsrj4w32fv06wldgzh7fc3yrhw8ayfs1rrwl4w660";
  };
in {
  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
    baseIndex = 1;
    extraConfig = ''
      run-shell '~/.tmux/tmux-gruvbox/gruvbox.tmux'

      unbind -a
      unbind-key C-b

      set -g prefix C-Space
      set -g mouse on
      set -g history-limit 5000
      set -g @continuum-restore 'on'
      set -g @continuum-save-interval '60'

      set-option -g allow-rename off
      set-option -g status-position top
      set -g status-bg '#282828'
      set-option -g status-right ""

      bind , command-prompt "rename-window %%"
      bind d detach
      bind '\' list-session
      bind c new-window
      bind s split-window -h
      bind v split-window -v
      bind x kill-pane
      bind ? list-keys

      bind -n M-':' command-prompt
      bind -n M-',' command-prompt "rename-window %%"
      bind -n M-'=' choose-tree
      bind -n M-d detach
      bind -n M-'\' list-session
      bind -n M-x kill-pane
      bind -n M-w new-window -c '#{pane_current_path}'
      bind -n M-h previous-window
      bind -n M-l next-window
      bind -n M-s split-window -h
      bind -n M-v split-window -v
      bind -n M-0 select-window -t:=0
      bind -n M-1 select-window -t:=1
      bind -n M-2 select-window -t:=2
      bind -n M-3 select-window -t:=3
      bind -n M-4 select-window -t:=4
      bind -n M-5 select-window -t:=5
      bind -n M-6 select-window -t:=6
      bind -n M-7 select-window -t:=7
      bind -n M-8 select-window -t:=8
      bind -n M-9 select-window -t:=9
      bind -n M-x kill-pane
      bind -n M-'?' list-keys

      bind-key C-Space send-prefix
      bind-key '=' choose-tree
      bind-key w new-window
      bind-key h previous-window
      bind-key l next-window
      bind-key h select-pane -L
      bind-key j select-pane -D
      bind-key k select-pane -U
      bind-key l select-pane -R
    '';
    plugins = with pkgs.tmuxPlugins; [
      better-mouse-mode
      continuum
      resurrect
      sensible
      vim-tmux-navigator
      yank
    ];
  };

  home.file.".tmux/tmux-gruvbox".source = "${gruvbox}/";
}
