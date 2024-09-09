{
  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      monitor = ",highres,auto,1";
      "exec" = "gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'";

      xwayland = {
        force_zero_scaling = true;
      };

      environment.variables = {
        NIXOS_OZONE_WL = "1";
        XDG_CURRENT_DESKTOP = "Hyprland";
        XDG_SESSION_TYPE = "wayland";
        XDG_SESSION_DESKTOP = "Hyprland";
        QT_QPA_PLATFORM = "wayland";
        QT_QPA_PLATFORMTHEME = "qt5ct";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        QT_AUTO_SCREEN_SCALE_FACTOR = "1";
        MOZ_ENABLE_WAYLAND = "1";
        WLR_NO_HARDWARE_CURSORS = "1";
        HYPRLAND_NO_SD_NOTIFY = "0";
      };

      "exec-once" = [
        "dunst"
        "swaybg -i $HOME/.config/dotfiles/wallpaper.jpg"
        "waybar"
      ];

      input = {
        follow_mouse = 1;
        touchpad = {
          natural_scroll = true;
          disable_while_typing = true;
          clickfinger_behavior = false;
          scroll_factor = 0.4;
        };
        accel_profile = "adaptive";
        sensitivity = 0.6;
      };

      gestures = {
        workspace_swipe = true;
        workspace_swipe_fingers = 3;
      };

      general = {
        sensitivity = 1;
        gaps_in = 6;
        gaps_out = 12;
        border_size = 1;
        "col.active_border" = "rgba(88c0d0ff)";
        "col.inactive_border" = "0xff434c5e";
        layout = "dwindle";
      };

      misc = {
        force_default_wallpaper = false;
      };

      decoration = {
        rounding = 3;
        dim_special = 0.7;
        blur = {
          special = false;
          enabled = false;
          size = 8;
          passes = 2;
        };
      };

      animations = {
        enabled = 1;
        animation = [
          "windows, 1, 6, wind, popin"
          "windowsIn, 1, 1, workIn, popin"
          "windowsOut, 1, 5, workIn, popin"
          "windowsMove, 1, 5, wind, slide"
          "fadeIn, 1, 2, winIn"
          "fadeOut, 1, 5, winOut"
          "workspaces, 1, 3, workIn, slidevert"
          "specialWorkspace, 1, 5, workIn, slidevert"
        ];
        bezier = [
          "wind, 0.05, 0.9, 0.1, 1.05"
          "winIn, 0.76, 0.42, 0.74, 0.87"
          "winOut, 0.76, 0.42, 0.74, 0.87"
          "workIn, 0.72, -0.07, 0.41, 0.98"
          "linear, 1, 1, 1, 1"
        ];
      };
      dwindle = {
        pseudotile = 1;
      };
      windowrule = [
        "float,file_progress"
        "float,confirm"
        "float,dialog"
        "float,download"
        "float,notification"
        "float,error"
        "float,splash"
        "float,confirmreset"
        "float,title:Open File"
        "float,title:branchdialog"
        "float,Lxappearance"
        "float,Rofi"
        "float,Wofi"
        "animation none,Wofi"
        "float,viewnior"
        "float,feh"
        "float,pavucontrol-qt"
        "float,pavucontrol"
        "float,file-roller"
        "fullscreen,wlogout"
        "float,title:wlogout"
        "fullscreen,title:wlogout"
        "idleinhibit focus,mpv"
        "idleinhibit fullscreen,firefox"
        "float,title:^(Media viewer)$"
        "float,title:^(Volume Control)$"
        "float,title:^(Picture-in-Picture)$"
        "float,title:^(Extract)$"
        "float,title:^(Save File)$"
        "size 800 600,title:^(Volume Control)$"
        "move 75 44%,title:^(Volume Control)$"
      ];

      windowrulev2 = [
        "opacity 0.9 0.9,class:^(code)$"
        "stayfocused,class:(wofi)"
        "noborder,class:(wofi)"
        "float,class:^(net.davidotek.pupgui2)$ #ProtonUp-Qt"
        "float,class:^(yad)$ #Protontricks-Gtk"
        "float,class:^(qt5ct)$"
        "float,class:^(nwg-look)$"
        "float,class:^(org.kde.ark)$"
        "float,class:^(pavucontrol)$"
        "float,class:^(blueman-manager)$"
        "float,class:^(nm-applet)$"
        "float,class:^(nm-connection-editor)$"
        "float,class:^(org.kde.polkit-kde-authentication-agent-1)$"
        "float,class:^(com.obsproject.Studio)$,title:^(Controls)$"
      ];

      bind = [
        "SUPER, C, killactive"
        "SUPER SHIFT, V, togglefloating"
        "ALT, F4, exec, hyprctl kill"
        "ALT, P, pin"
        "SUPER, F, fullscreen"
        "SUPER SHIFT, Q, exec, power-menu"
        "SUPER, U, exec, swaylock"
        "SUPER, Return, exec, foot"
        "SUPER, B, exec, google-chrome-stable"
        "SUPER, W, exec, firefox"
        "SUPER, N, exec, nemo"
        "SUPER, V, exec, code"
        "SUPER, SPACE, exec, wofi -S run --prompt=Run"
        "SUPER SHIFT, SPACE, exec, wofi -S drun --prompt=Run"
        ", XF86AudioRaiseVolume, exec, amixer -q set Master 2%+ unmute"
        ", XF86AudioLowerVolume, exec, amixer -q set Master 2%- unmute"
        ", XF86AudioMute, exec, amixer -q set Master toggle"
        ", XF86MonBrightnessUp, exec, brightnessctl set +2%"
        ", XF86MonBrightnessDown, exec, brightnessctl set 2%-"
        ", Print, exec, grimblast --notify copy screen --prompt=RUN"
        "SUPER ,Print, exec, grimblast --notify copy area --prompt=RUN"
        "SUPER, G, exec, screen-record"
        "SUPERSHIFT, G, exec, stop-screen-record"
        "SUPER, H, movefocus, l"
        "SUPER, J, movefocus, d"
        "SUPER, K, movefocus, u"
        "SUPER, L, movefocus, r"
        "SUPER, 1, exec, hyprctl dispatch workspace 1"
        "SUPER, 2, exec, hyprctl dispatch workspace 2"
        "SUPER, 3, exec, hyprctl dispatch workspace 3"
        "SUPER, 4, exec, hyprctl dispatch workspace 4"
        "SUPER, 5, exec, hyprctl dispatch workspace 5"
        "SUPER, 6, exec, hyprctl dispatch workspace 6"
        "SUPER, 7, exec, hyprctl dispatch workspace 7"
        "SUPER, 8, exec, hyprctl dispatch workspace 8"
        "SUPER, 9, exec, hyprctl dispatch workspace 9"
        "SUPER, 0, exec, hyprctl dispatch workspace 10"
        "SUPER CTRL, right, workspace, r+1"
        "SUPER CTRL, left, workspace, r-1"
        "SUPER CTRL, down, workspace, empty"
        "SUPER SHIFT, h, movewindow, l"
        "SUPER SHIFT, l, movewindow, r"
        "SUPER SHIFT, k, movewindow, u"
        "SUPER SHIFT, j, movewindow, d"
        "SUPER SHIFT, 1, movetoworkspace, 1"
        "SUPER SHIFT, 2, movetoworkspace, 2"
        "SUPER SHIFT, 3, movetoworkspace, 3"
        "SUPER SHIFT, 4, movetoworkspace, 4"
        "SUPER SHIFT, 5, movetoworkspace, 5"
        "SUPER SHIFT, 6, movetoworkspace, 6"
        "SUPER SHIFT, 7, movetoworkspace, 7"
        "SUPER SHIFT, 8, movetoworkspace, 8"
        "SUPER SHIFT, 9, movetoworkspace, 9"
        "SUPER SHIFT, 0, movetoworkspace, 10"
        "SUPER, mouse_down, workspace, e+1"
        "SUPER, mouse_up, workspace, e-1"
        "SUPER, Y, togglesplit, # dwindle"
        "SUPER ALT, 1, movetoworkspacesilent, 1"
        "SUPER ALT, 2, movetoworkspacesilent, 2"
        "SUPER ALT, 3, movetoworkspacesilent, 3"
        "SUPER ALT, 4, movetoworkspacesilent, 4"
        "SUPER ALT, 5, movetoworkspacesilent, 5"
        "SUPER ALT, 6, movetoworkspacesilent, 6"
        "SUPER ALT, 7, movetoworkspacesilent, 7"
        "SUPER ALT, 8, movetoworkspacesilent, 8"
        "SUPER ALT, 9, movetoworkspacesilent, 9"
        "SUPER ALT, 0, movetoworkspacesilent, 10"
      ];

      binde = [
        "SUPER SHIFT, D, resizeactive, 30 0"
        "SUPER SHIFT, A, resizeactive, -30 0"
        "SUPER SHIFT, W, resizeactive, 0 -30"
        "SUPER SHIFT, S, resizeactive, 0 30"
      ];

      bindm = [
        "SUPER, mouse:272, movewindow"
        "SUPER, mouse:273, resizewindow"
      ];
    };
  };
}
