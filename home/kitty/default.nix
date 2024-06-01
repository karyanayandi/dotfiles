{
  programs.kitty = {
    enable = true;
    font = {
      name = "Fira Code Mono Nerd Font";
      size = 11;
    };
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
    extraConfig = ''
      background #1d2021
      foreground #d4be98
      selection_background #d4be98
      selection_foreground #1d2021
      cursor #a89984
      cursor_text_color background
      active_tab_background #1d2021
      active_tab_foreground #d4be98
      active_tab_font_style bold
      inactive_tab_background #1d2021
      inactive_tab_foreground #a89984
      inactive_tab_font_style normal
      color0 #665c54
      color8 #928374
      color1 #ea6962
      color9 #ea6962
      color2 #a9b665
      color10 #a9b665
      color3 #e78a4e
      color11 #d8a657
      color4 #7daea3
      color12 #7daea3
      color5 #d3869b
      color13 #d3869b
      color6 #89b482
      color14 #89b482
      color7 #d4be98
      color15 #d4be98
    '';
  };
}
