-- ~/.config/hypr/autostart.lua

hl.on("hyprland.start", function()
	-- GTK / cursor theme
	hl.exec_cmd("gsettings set org.gnome.desktop.interface Tela-grey-dark")
	hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic'")
	hl.exec_cmd("gsettings set org.gnome.desktop.interface font-name 'Adwaita Sans 11'")
	hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'")

	-- Portals
	hl.exec_cmd("/usr/lib/xdg-desktop-portal-hyprland")
	hl.exec_cmd("/usr/lib/xdg-desktop-portal")

	-- Polkit agent
	hl.exec_cmd("systemctl --user start --now hyprpolkitagent.service")

	-- Wallpaper / bar / notifications
	hl.exec_cmd("hyprpaper")
	hl.exec_cmd("sh ~/.local/bin/random-wallpaper.sh")
	hl.exec_cmd("swaync")
	hl.exec_cmd("swayosd-server")
	hl.exec_cmd("vicinae server")
	hl.exec_cmd("waybar")
end)
