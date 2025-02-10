{pkgs, ...}: {
  services.dunst = {
    enable = true;
    iconTheme = {
      package = pkgs.papirus-nord;
      name = "Papirus";
    };
    settings = {
      global = {
        origin = "top-right";
        geometry = "320x120-28-28";
        separator_height = 2;
        padding = 32;
        horizontal_padding = 16;
        text_icon_padding = 16;
        frame_width = 0;
        idle_threshold = 120;
        line_height = 12;
        format = ''
          <b>%s</b>
          %b'';
        alignment = "center";
        icon_position = "off";
        startup_notification = "false";
        corner_radius = 4;
        timeout = 2;
      };
    };
  };
}
