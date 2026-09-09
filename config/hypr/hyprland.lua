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
    rounding = 15,
    rounding_power = 2,

    active_opacity = 1.0,
    inactive_opacity = 1.0,
    fullscreen_opacity = 1.0,

    shadow = {
      enabled = true,
      range = 4,
      render_power = 3,
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

-- Generated colors only; use Hyprland's module loader like the modules above.
require "colors"
