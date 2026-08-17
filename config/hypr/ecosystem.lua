-- ~/.config/hypr/ecosystem.lua

hl.config {
  ecosystem = {
    enforce_permissions = true,
    no_donation_nag = true,
    no_update_news = true,
  },
}

-- Screencopy / plugin permissions
local screencopy_bins = {
  "/usr/lib/xdg-desktop-portal-hyprland",
  "/usr/lib/xdg-desktop-portal",
  "/usr/libexec/xdg-desktop-portal-hyprland",
  "/usr/libexec/xdg-desktop-portal",
  "/usr/lib64/xdg-desktop-portal-hyprland",
  "/usr/lib64/xdg-desktop-portal",
  "/usr/bin/grim",
  "/usr/local/bin/grim",
  "/usr/sbin/grim",
  "/usr/bin/hyprlock",
  "/usr/local/bin/hyprlock",
  "/usr/sbin/hyprlock",
  "/usr/bin/hyprpicker",
  "/usr/local/bin/hyprpicker",
  "/usr/sbin/hyprpicker",
  "/usr/bin/wf-recorder",
  "/usr/local/bin/wf-recorder",
  "/usr/sbin/wf-recorder",
}

for _, bin in ipairs(screencopy_bins) do
  hl.permission { binary = bin, type = "screencopy", mode = "allow" }
end

local plugin_bins = {
  "/usr/bin/hyprpm",
  "/usr/local/bin/hyprpm",
  "/usr/sbin/hyprpm",
}

for _, bin in ipairs(plugin_bins) do
  hl.permission { binary = bin, type = "plugin", mode = "allow" }
end
