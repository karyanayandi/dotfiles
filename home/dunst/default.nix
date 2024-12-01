{...}: {
  services.dunst = {
    enable = true;
    settings = {
      global = {
        origin = "bottom-right";
        offset = "60x12";
        separator_height = 2;
        padding = 12;
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
