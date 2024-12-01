{...}: {
  services.dunst = {
    enable = true;
    settings = {
      global = {
        origin = "bottom-right";
        geometry = "320x120-32-32";
        separator_height = 2;
        padding = 32;
        horizontal_padding = 12;
        text_icon_padding = 12;
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
