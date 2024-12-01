{pkgs, ...}: let
  custom-theme = pkgs.fetchFromGitHub {
    owner = "karyanayandi";
    repo = "custom-tmux-theme";
    rev = "main";
    sha256 = "1zvhpgfwdar10xk561r7plci8r1jqaf3di32zl9zjpnpnwxyq5ms";
  };
in {
  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
    baseIndex = 1;
    extraConfig = ''
      unbind-key C-b

      # set -g status off
      set -g status-position top
      set -g prefix C-Space
      set -g mouse on
      set -g history-limit 5000

      bind C-Space send-prefix
      bind d detach
      bind '\' list-session
      bind w new-window
      bind s split-window -h
      bind v split-window -v
      bind x kill-pane
      bind ? list-keys
      bind , command-prompt "rename-session %%"

      bind -n M-':' command-prompt
      bind -n M-',' command-prompt "rename-session %%"
      bind -n M-'=' choose-tree
      bind -n M-d detach
      bind -n M-'\' list-session
      bind -n M-r source-file ~/.tmux.conf
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

      bind-key '=' choose-tree
      bind-key w new-window
      bind-key h previous-window
      bind-key l next-window
      bind-key h select-pane -L
      bind-key j select-pane -D
      bind-key k select-pane -U
      bind-key l select-pane -R

      run-shell '~/.tmux/custom-tmux-theme/custom-theme.tmux'
    '';
    plugins = with pkgs.tmuxPlugins; [
      better-mouse-mode
      vim-tmux-navigator
      sensible
      yank
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '60'
        '';
      }
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-save 'S'
          set -g @resurrect-restore 'R'
          set -g @resurrect-strategy-nvim 'session'
        '';
      }
    ];
  };
  home.file.".tmux/custom-tmux-theme".source = "${custom-theme}/";
}
