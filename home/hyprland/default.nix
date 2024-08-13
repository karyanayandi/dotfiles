{pkgs, ...}: {
  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      source = "${pkgs.writeText "rose-pine.conf" (builtins.readFile "/home/karyana/.config/nixos/home/hyprland/rose-pine.conf")}";

      monitor = ",highres,auto,1";
      "exec" = "gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'";

      xwayland = {
        force_zero_scaling = true;
      };

      "exec-once" = [
        "dunst"
        "swaybg -i $HOME/Downloads/lake.jpg"
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
        kb_options = "caps:escape";
      };

      general = {
        sensitivity = 1;
        gaps_in = 6;
        gaps_out = 12;
        border_size = 1;
        "col.active_border" = "$rose";
        "col.inactive_border" = "$muted";
        layout = "dwindle";
      };

      decoration = {
        rounding = 4;
      };

      animations = {
        enabled = 1;
        animation = [
          "workspaces,1,4,default"
          "windows,1,5,overshot,slide"
          "windowsOut,1,4,smoothOut,slide"
          "windowsMove,1,4,default"
          "border,1,10,default"
          "fade,1,10,smoothIn"
          "fadeDim,1,10,smoothIn"
          "workspaces,1,6,default"
        ];
        bezier = [
          "overshot,0.05,0.9,0.1,1.05"
          "smoothOut,0.36,0,0.66,-0.56"
          "smoothIn,0.25,1,0.5,1"
        ];
      };

      dwindle = {
        pseudotile = 1;
      };

      gestures = {
        workspace_swipe = true;
        workspace_swipe_invert = true;
        workspace_swipe_min_speed_to_force = 6;
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
        "size 800 600,title:^(Volume Control)$"
        "move 75 44%,title:^(Volume Control)$"
      ];

      windowrulev2 = [
        "opacity 0.9 0.9,class:^(foot)$"
        "stayfocused,class:(wofi)"
        "noborder,class:(wofi)"
      ];

      bind = [
        "SUPER,Return,exec,foot"
        "SUPERSHIFT,Q,killactive,"
        "SUPER,V,togglefloating,"
        "SUPER,C,exec,grimblast --notify copy screen --propmt=RUN,"
        "SUPERSHIFT,C,exec,grimblast --notify copy area --propmt=RUN,"
        "SUPER,SPACE,exec,wofi -S run --prompt=Run"
        "SUPER,F,fullscreen,0"
        "SUPER,h,movefocus,l"
        "SUPER,l,movefocus,r"
        "SUPER,k,movefocus,u"
        "SUPER,j,movefocus,d"
        "SUPER,mouse_down,workspace,e+1"
        "SUPER,mouse_up,workspace,e-1"
        "SUPER,g,togglegroup"
        "SUPER,tab,changegroupactive"
        "SUPERSHIFT,E,exec,hyprctl dispatch exit"
        "SUPER CTRL,left,resizeactive,-20 0"
        "SUPER CTRL,right,resizeactive,20 0"
        "SUPER CTRL,up,resizeactive,0 -20"
        "SUPER CTRL,down,resizeactive,0 20"
        "SUPERSHIFT,h,movewindow,l"
        "SUPERSHIFT,l,movewindow,r"
        "SUPERSHIFT,k,movewindow,u"
        "SUPERSHIFT,j,movewindow,d"
        "SUPER,1,workspace,1"
        "SUPER,2,workspace,2"
        "SUPER,3,workspace,3"
        "SUPER,4,workspace,4"
        "SUPER,5,workspace,5"
        "SUPER,6,workspace,6"
        "SUPER,7,workspace,7"
        "SUPER,8,workspace,8"
        "SUPER,9,workspace,9"
        "SUPERSHIFT,1,movetoworkspacesilent,1"
        "SUPERSHIFT,2,movetoworkspacesilent,2"
        "SUPERSHIFT,3,movetoworkspacesilent,3"
        "SUPERSHIFT,4,movetoworkspacesilent,4"
        "SUPERSHIFT,5,movetoworkspacesilent,5"
        "SUPERSHIFT,6,movetoworkspacesilent,6"
        "SUPERSHIFT,7,movetoworkspacesilent,7"
        "SUPERSHIFT,8,movetoworkspacesilent,8"
        "SUPERSHIFT,9,movetoworkspacesilent,9"
        ",XF86MonBrightnessUp,exec,brightnessctl set +2%"
        ",XF86MonBrightnessDown,exec,brightnessctl set 2%-"
        ",XF86AudioRaiseVolume,exec,amixer -q set Master 2%+ unmute"
        ",XF86AudioLowerVolume,exec,amixer -q set Master 2%- unmute"
        ",XF86AudioMute,exec,amixer -q set Master toggle"
      ];

      bindm = [
        "SUPER,mouse:272,movewindow"
        "SUPER,mouse:273,resizewindow"
      ];
    };
  };
}
