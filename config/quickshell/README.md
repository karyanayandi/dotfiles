# Quickshell island

Desktop panels live in `modules/Island.qml`, except capture controls in `modules/CaptureWindow.qml`. Capture hides only its own window, so screenshots and recordings can include the launcher. Shared controls use `Theme.qml`, Nerd Font glyphs, keyboard focus rings, and the existing Matugen palette. `Config.reducedMotion` disables island geometry animation.

## Shortcuts

`Mod` is Super. Bindings are in `config/hypr/bind.lua` and the existing Niri config.

| Shortcut | Action |
| --- | --- |
| Mod+Alt+A | Audio mixer |
| Mod+Alt+Y | Media |
| Mod+Alt+C | Calendar, also click bar clock |
| Mod+Alt+D | Displays |
| Print | Screenshot panel, area |
| Ctrl+Print | Screenshot panel, screen |
| Alt+Print | Screenshot panel, window |
| Mod+G | Recording panel |
| Mod+Alt+G | Recording panel, area |
| Mod+Shift+G | Stop and finalize recording |
| Mod+Alt+P | Color picker |
| Mod+Alt+S, Hyprland | Control center |

Control center also opens every panel and lists removable drives and Codex limits. Existing screenshot/recording/color-picker shell scripts forward to Quickshell for compatibility.

Tab/Shift+Tab navigate; Space activates buttons; Escape closes. Calendar arrows move between days. Icon-only actions have accessible names and tooltips. Selects and inputs use shared rounded, themed controls.

## Features and boundaries

Menus and dropdowns use full content height without scrolling. Launcher results, notifications, and the separate capture editor scroll. Oversized non-scrolling menus can extend beyond the screen.

- Audio uses PipeWire device/stream volume, mute, and default input/output selection. Media uses MPRIS and capability-gates transport and seeking.
- Calendar browses dates. No event sync or calendar account required.
- Capture has Screenshot/Recording tabs and an action footer. Screenshot captures screen, visible window region, or area. Drag preview to select a crop or rectangle annotation; Exact bounds supplies keyboard-accessible pixel controls. Undo retains 20 edits. Native editing provides freehand markers, arrows, text, color and stroke width. Drag to draw; release applies through ImageMagick. For keyboard placement, use Exact bounds and Draw from bounds or Add text. Copy and Save include edits; Undo restores the previous bitmap. Window-only video is not implemented.
- Recording accepts screen/area and one audio source, including monitor or microphone sources. No audio by default. Screen mode selects a whole monitor with one click; Area mode uses drag selection. Bar shows elapsed recording time only while recording. Click it to stop. Stop sends SIGINT only to the owned recorder and waits for finalization. Shell reload also finalizes recording; unsaved screenshot previews are temporary.
- Clipboard copies allow wl-copy's background selection owner to outlive the request without holding its completion pipes open.
- PNGs save under the XDG Pictures directory's `Screenshots`; videos under XDG Videos `Records`. Nothing overwrites existing files. Image/color copy happens only on explicit action.
- Color picker exposes HEX and RGB. Sample swatch intentionally shows the sampled color; its surrounding UI follows Matugen.
- Displays support active Hyprland 0.56 Lua configuration. Resolution, rate, scale, position, and rotation have a detached 20-second rollback watchdog. Keep is session-only. Save persists `~/.config/quickshell/displays.lua`, loaded by `hyprland.lua`. Display enable/disable and mirrored layouts are not supported.
- Drives use UDisks2, never sudo or forced unmount. Internal/system and encrypted volumes are excluded. Some USB SSDs reporting non-removable are intentionally excluded. Unmount sibling volumes before ejecting.
- Codex is information-only. While control center is open, limits refresh every minute through `codex app-server` using existing CLI authentication. No login, quota-reset action, or model request. Failed live reads fall back to clearly labeled cached data; cached account attribution is unverified. Passed reset timestamps never invent fresh usage.

## Polkit

`Config.polkitAgentEnabled` enables Quickshell's native Polkit agent. Real requests appear in the island and block other panel/focus paths. Passwords are masked, submitted directly to the native flow, cleared afterward, and never exposed through IPC or logs.

Existing `hyprpolkitagent.service` was stopped and disabled after native registration and cancellation checks. Both compositor configs no longer launch another agent. Keep the fallback package installed.

Fallback:

1. Set `polkitAgentEnabled: false` in `Config.qml` and allow Quickshell to reload.
2. Run `systemctl --user enable --now hyprpolkitagent.service`.

Never intentionally run both agents. Successful-password authentication still needs a manual check; automated checks only open/cancel a harmless `pkexec /usr/bin/true` request.

## Backends

Quickshell 0.3.1 with PipeWire, MPRIS, and Polkit modules; Python 3; UDisks2 and python-gobject; grim, slurp, wf-recorder, hyprpicker, wl-copy, pactl, ImageMagick. Missing tools show an error rather than running an unrelated app. Codex CLI is optional. Display settings require the active Hyprland Lua API. Niri-specific paths were not live-tested.

## Checks

Run from repository root:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 config/quickshell/scripts/test-capture.py
PYTHONDONTWRITEBYTECODE=1 python3 config/quickshell/scripts/test-capture-editor.py
PYTHONDONTWRITEBYTECODE=1 python3 config/quickshell/scripts/test-menu-layouts.py
PYTHONDONTWRITEBYTECODE=1 python3 config/quickshell/scripts/test-capture.py
PYTHONDONTWRITEBYTECODE=1 python3 config/quickshell/scripts/test-control-extras.py
PYTHONDONTWRITEBYTECODE=1 python3 config/quickshell/scripts/test-codex-limits.py
PYTHONDONTWRITEBYTECODE=1 python3 config/quickshell/scripts/test-display-settings.py
sh config/quickshell/scripts/test-theme.sh
QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input config/quickshell/modules/panels/tst_calendar.qml -o -,txt
```

Opt-in live UI checks, with panels closed and no recording active:

```sh
python3 config/quickshell/scripts/test-island.py --live --selector --polkit
```

This opens/closes panels, uses wtype to cancel a real selector, and cancels a native authentication request without submitting a password. It does not change displays, mount drives, or save captures.

Live checks also covered an unchanged-mode watchdog trial, real grim capture, ImageMagick cropping, and recorder stop/finalization into playable H.264. Removable hardware actions and successful password authentication remain manual checks.
