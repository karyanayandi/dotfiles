-- ~/.config/hypr/bind.lua

local terminal = "foot"
local fileManager = "nemo"
local browser = "helium-browser"
local mainMod = "SUPER"

-- Apps
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd "foot")
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + SHIFT + Space", hl.dsp.exec_cmd "qs ipc call launcher open apps")
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + ALT + L", hl.dsp.exec_cmd "hyprlock")

-- Window state
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen { mode = "fullscreen" })
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen { mode = "maximized", action = "toggle" })
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(
  mainMod .. " + ALT + Q",
  hl.dsp.exec_cmd "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"
)
hl.bind(mainMod .. " + V", hl.dsp.window.float { action = "toggle" })

-- Launcher
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd "qs ipc call launcher open apps")
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd "qs ipc call launcher open clipboard")
hl.bind(mainMod .. " + ALT + E", hl.dsp.exec_cmd "qs ipc call launcher open emoji")
hl.bind(mainMod .. " + ALT + N", hl.dsp.exec_cmd "qs ipc call launcher open nerd")
hl.bind(mainMod .. " + ALT + B", hl.dsp.exec_cmd "qs ipc call launcher open bluetooth")
hl.bind(mainMod .. " + ALT + A", hl.dsp.exec_cmd "qs ipc call launcher open audio")

-- Dwindle layout extras
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.window.pseudo { action = "toggle" })
hl.bind(mainMod .. " + SHIFT + S", function()
  hl.dispatch(hl.dsp.layout "togglesplit")
  hl.dispatch(hl.dsp.window.move { workspace = "special:magic" })
end)

-- Screen recording / screenshots
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd "~/.local/bin/screen-record.sh")
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.exec_cmd "~/.local/bin/stop-screen-record.sh")
hl.bind(mainMod .. " + ALT + G", hl.dsp.exec_cmd "~/.local/bin/screen-record-area.sh")
hl.bind(mainMod .. " + ALT + P", hl.dsp.exec_cmd "~/.local/bin/color-picker.sh")
hl.bind("Print", hl.dsp.exec_cmd "~/.local/bin/screenshot.sh")

-- Notifications
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd "qs ipc call notifications toggle")
hl.bind(mainMod .. " + ALT + N", hl.dsp.exec_cmd "qs ipc call notifications clear")

-- Focus
hl.bind(mainMod .. " + H", hl.dsp.focus { direction = "l" })
hl.bind(mainMod .. " + L", hl.dsp.focus { direction = "r" })
hl.bind(mainMod .. " + J", hl.dsp.focus { direction = "u" })
hl.bind(mainMod .. " + K", hl.dsp.focus { direction = "d" })

-- Move windows
hl.bind(mainMod .. " + SHIFT + comma", hl.dsp.window.move { direction = "l" })
hl.bind(mainMod .. " + SHIFT + period", hl.dsp.window.move { direction = "r" })

-- Scrolling layout
hl.bind(mainMod .. " + R", hl.dsp.layout "colresize +conf")
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.layout "swapcol l")
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.layout "swapcol r")

-- Workspaces
for i = 1, 9 do
  hl.bind(mainMod .. " + " .. i, hl.dsp.focus { workspace = tostring(i) })
  hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move { workspace = tostring(i) })
end
hl.bind(mainMod .. " + 0", hl.dsp.focus { workspace = "10" })
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move { workspace = "10" })

-- Special workspace
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special "magic")

-- Mouse workspace switching
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus { workspace = "e+1" })
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus { workspace = "e-1" })

-- Mouse drag / resize
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Repeatable resize
hl.bind(mainMod .. " + equal", hl.dsp.window.resize { x = 50, y = 0, relative = true }, { repeating = true })
hl.bind(mainMod .. " + minus", hl.dsp.window.resize { x = -50, y = 0, relative = true }, { repeating = true })

-- Volume (quickshell OSD + wpctl, no swayosd)
hl.bind(
  "XF86AudioRaiseVolume",
  hl.dsp.exec_cmd "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ -l 1.0",
  { locked = true, repeating = true }
)
hl.bind(
  "XF86AudioLowerVolume",
  hl.dsp.exec_cmd "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",
  { locked = true, repeating = true }
)
hl.bind(
  "XF86AudioMute",
  hl.dsp.exec_cmd "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
  { locked = true, repeating = true }
)
hl.bind(
  "XF86AudioMicMute",
  hl.dsp.exec_cmd "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle",
  { locked = true, repeating = true }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd "brightnessctl -e4 -n2 set 5%+", { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd "brightnessctl -e4 -n2 set 5%-", { locked = true, repeating = true })

-- Media keys (locked)
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd "playerctl play-pause", { locked = true })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd "playerctl stop", { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd "playerctl previous", { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd "playerctl next", { locked = true })
