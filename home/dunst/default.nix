{pkgs, ...}: {
  services.dunst = {
    enable = true;
    iconTheme = {
      package = pkgs.tela-icon-theme;
      name = "Tela-black";
    };
    settings = {
      global = {
        corner_radius = 16;
        follow = "mouse";
        width = "(0, 600)";
        height = 100;
        origin = "bottom-right";
        offset = "40x20";
        progress_bar = true;
        progress_bar_height = 10;
        progress_bar_frame_width = 1;
        progress_bar_min_width = 150;
        progress_bar_max_width = 400;
        progress_bar_corner_radius = 0;
        separator_height = 2;
        padding = 10;
        horizontal_padding = 15;
        text_icon_padding = 15;
        frame_width = 2;
        gap_size = 7;
        sort = "yes";
        alignment = "left";
        vertical_alignment = "center";
        show_age_threshold = 60;
        ellipsize = "middle";
        ignore_newline = "no";
        stack_duplicates = true;
        hide_duplicate_count = false;
        show_indicators = "yes";
      };
    };
  };
}
