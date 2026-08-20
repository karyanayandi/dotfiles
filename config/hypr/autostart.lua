-- ~/.config/hypr/autostart.lua

local function autostart_lock()
  return (os.getenv "XDG_RUNTIME_DIR" or "/tmp")
    .. "/hypr-autostart-"
    .. (os.getenv "HYPRLAND_INSTANCE_SIGNATURE" or "none")
end

hl.on("hyprland.start", function()
  -- Run autostart once per Hyprland instance. hyprland.start can fire on
  -- config reloads, and re-spawning portals/polkit causes CPU spikes.
  local lock = autostart_lock()
  local f = io.open(lock, "r")
  if f then
    f:close()
    return
  end

  -- GTK / cursor theme
  hl.exec_cmd "gsettings set org.gnome.desktop.interface icon-theme 'Tela-grey-dark'"
  hl.exec_cmd "gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice'"
  hl.exec_cmd "gsettings set org.gnome.desktop.interface font-name 'Adwaita Sans 11'"
  hl.exec_cmd "gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'"

  -- Export Wayland env to the systemd/D-Bus user session so portals start cleanly
  hl.exec_cmd "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"

  -- Nuclear portal restart: kill stale xdph/xdg-desktop-portal, then launch fresh.
  -- This works around xdg-desktop-portal-hyprland v1.4.0 spinning CPU on reload/resume.
  hl.exec_cmd "sh ~/.config/hypr/restart-portals.sh"

  -- Polkit agent
  hl.exec_cmd "systemctl --user start --now hyprpolkitagent.service"

  -- Services (ollama + opencodex; idempotent, safe alongside boot services)
  hl.exec_cmd "sh ~/.config/dotfiles/setup/start-services.sh"

  -- Wallpaper / bar / notifications
  hl.exec_cmd "hyprpaper"
  hl.exec_cmd "sh ~/.local/bin/set-wallpaper.sh"
  hl.exec_cmd "swaync"
  hl.exec_cmd "swayosd-server"
  hl.exec_cmd "vicinae server"
  hl.exec_cmd "waybar"

  io.open(lock, "w"):close()
end)

hl.on("hyprland.shutdown", function()
  os.remove(autostart_lock())
end)
