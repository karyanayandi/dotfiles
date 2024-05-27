{
  programs.kitty = {
    enable = true;
    font = {
      name = "Fira Code Mono Nerd Font";
      size = 11;
    };
    theme = "Gruvbox Dark";
    settings = {
      confirm_os_window_close = 0;
      tab_bar_style = "powerline";
      adjust_line_height = "100%";
      cursor_shape = "beam";
    };
    keybindings = {
      "shift+up" = "scroll_line_up";
      "shift+down" = "scroll_line_down";
      "ctrl+shift+a" = "previous_tab";
      "ctrl+shift+d" = "next_tab";
    };
  };
}
