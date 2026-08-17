-- ~/.config/hypr/hyprland.lua
-- Hyprland 0.55+ Lua configuration

-- Monitor fallback
hl.monitor {
  output = "",
  mode = "preferred",
  position = "auto",
  scale = "auto",
}

-- General settings
hl.config {
  general = {
    gaps_in = 8,
    gaps_out = 16,
    border_size = 3,
    col = {
      active_border = "rgba(189,174,147,1)",
      -- inactive_border = "rgba(124,111,100,1)",
    },
    resize_on_border = true,
    allow_tearing = true,
    layout = "scrolling",
    snap = {
      enabled = true,
    },
  },
}

-- Decoration
hl.config {
  decoration = {
    rounding = 5,
    rounding_power = 2,

    active_opacity = 1.0,
    inactive_opacity = 1.0,
    fullscreen_opacity = 1.0,

    shadow = {
      enabled = true,
      range = 4,
      render_power = 3,
      color = "rgba(1a1a1aee)",
    },

    blur = {
      enabled = true,
      size = 10,
      passes = 1,
      vibrancy = 0.1696,
    },
  },
}

-- Input
hl.config {
  input = {
    kb_layout = "us",
    kb_variant = "",
    kb_model = "",
    kb_options = "",
    kb_rules = "",
    follow_mouse = 1,
    sensitivity = 0,
    touchpad = {
      natural_scroll = false,
    },
  },
}

-- Per-device overrides
hl.device {
  name = "epic-mouse-v1",
  sensitivity = -0.5,
}

-- Touchpad workspace swipe
hl.gesture {
  fingers = 3,
  direction = "horizontal",
  action = "workspace",
}

-- Modular configuration
require "animations"
require "autostart"
require "bind"
require "ecosystem"
require "env"
require "layout"
require "misc"
require "windowrule"
