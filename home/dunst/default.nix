{pkgs, ...}: {
  services.dunst = {
    enable = true;
    iconTheme = {
      package = pkgs.tela-icon-theme;
      name = "Tela-dark";
    };
    settings = {
      global = {
        origin = "bottom-right";
        geometry = "320x120-28-28";
        separator_height = 0;
        padding = 32;
        horizontal_padding = 12;
        text_icon_padding = 12;
        frame_width = 4;
        idle_threshold = 120;
        show_age-threshole = 60;
        line_height = 0;
        format = ''
          <b>%s</b>
          %b'';
        alignment = "left";
        icon_position = "off";
        startup_notification = "false";
        corner_radius = 10;
        timeout = 2;
        hide_duplicate_count = false;
      };
    };
  };
}
