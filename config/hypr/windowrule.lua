-- ~/.config/hypr/windowrule.lua

-- Suppress maximize events
hl.window_rule({
	name = "suppress-maximize-events",
	match = { class = ".*" },
	suppress_event = "maximize",
})

-- Fix XWayland drag windows
hl.window_rule({
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},
	no_focus = true,
})

-- Hyprland run floating launcher
hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },
	move = { "20", "monitor_h-120" },
	float = true,
})

-- Common floating apps
hl.window_rule({ name = "mpv", match = { class = "^(mpv)$" }, float = true })
hl.window_rule({ name = "imv", match = { class = "^(imv)$" }, float = true })
hl.window_rule({
	name = "fileroller",
	match = { class = "^(org.gnome.FileRoller)$" },
	float = true,
	size = { 1000, 600 },
})
hl.window_rule({
	name = "bitwarden",
	match = { class = "^(chrome-nngceckbapebfimnlniiiahkandclblb-Default)$" },
	float = true,
})
hl.window_rule({
	name = "xdg-desktop-portal-gtk",
	match = { class = "^(xdg-desktop-portal-gtk)$" },
	float = true,
	size = { 1200, 800 },
})
hl.window_rule({
	name = "pavucontrol",
	match = { class = "^(org.pulseaudio.pavucontrol)$" },
	float = true,
	size = { 1000, 600 },
})
hl.window_rule({
	name = "picture-in-picture",
	match = { title = ".*[Pp]icture.?in.?[Pp]icture.*" },
	float = true,
	pin = true,
	keep_aspect_ratio = true,
	size = { 480, 270 },
	move = { "monitor_w-500", "monitor_h-290" },
})

-- Layer rules
hl.layer_rule({ name = "quickshell-noanim", match = { namespace = "quickshell" }, no_anim = true })
hl.layer_rule({ name = "quickshell-noblur", match = { namespace = "quickshell" }, blur = false })
hl.layer_rule({ name = "vicinae-blur", match = { namespace = "vicinae" }, blur = true, ignore_alpha = 0 })
hl.layer_rule({ name = "vicinae-no-animation", match = { namespace = "vicinae" }, no_anim = true })
