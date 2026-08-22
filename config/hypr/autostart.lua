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

  -- Services (ollama + 9router; idempotent, safe alongside boot services)
  -- 9router: node script + interactive TUI. `--skip-update` + non-TTY stdin = tray
  -- (headless) mode; without it the TUI exits on stdin EOF.
  -- Idempotency via pidfile + kill -0: pgrep is unusable here (its own sh -c
  -- cmdline contains the launch token "9router", so it always self-matches).
  -- Keep the pidfile read UNQUOTED. exec_cmd's tokenizer mangles "$(...)".
  -- hl.exec_cmd "pgrep -x ollama >/dev/null || nohup ollama serve >/tmp/ollama.log 2>&1 &"
  hl.exec_cmd "if ! kill -0 $(cat /tmp/9router.pid 2>/dev/null) 2>/dev/null; then nohup 9router --skip-update >/tmp/9router.log 2>&1 & echo $! >/tmp/9router.pid; fi"

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
