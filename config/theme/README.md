# Live wallpaper colors

`~/.local/bin/wallpaper-theme` renders colors, then refreshes running consumers.

- GTK3 alternates generated `matugen-dark` themes through GSettings after each
  render. Colors belong to the named theme, not the startup-only user CSS.
  Log out/in once to drop the old `GTK_THEME` override and cached user CSS.
  GTK4 uses generated user CSS and needs an app restart. The named-theme
  experiment did not work reliably in Pavucontrol; live reload is unresolved.
  X11 apps also need a desktop settings bridge that forwards GSettings to XSettings.
- Set `QT_QPA_PLATFORMTHEME=qt5ct` for both Qt versions. Qt6ct also registers
  the `qt5ct` key; `qt6ct;qt5ct` falls back to the default palette here.
  Log out/in after changing this variable so launchers and apps inherit it.
- Qt5/Qt6 apps using qt5ct/qt6ct reload about 3 seconds after a temporary entry
  is created and removed in their config directory. Touching a symlinked config
  target does not notify this directory watcher.
  Apps using another platform theme or their own palette are not covered.
- Ghostty reloads its app config with `SIGUSR2`, so new windows also inherit the
  new palette. Only processes with a registered signal handler receive it.
  `window-theme = ghostty` also recolors GTK tabs, titlebars and popovers on
  reload. Source-checked for Ghostty 1.3.1's GTK 4.16+ path, used by installed
  GTK 4.22: `auto` only selects light/dark, while `ghostty` rebuilds GTK CSS
  colors from the config. Startup-loaded GTK user CSS overrides that provider.
  `gtk-custom-css` reloads `gtk-4.0/colors.css` at user priority so native tabs,
  popovers and accents receive the new palette too. Verified with native GTK
  color probes; existing windows still need visual review.
- Lazygit and Lazydocker theme templates use ANSI names instead of RGB literals.
  Existing OSC terminal-palette updates recolor these cells without app config
  reloads. Selected rows use reverse video for contrast rather than a fixed RGB
  background. Lazydocker's ignored Git-only theme fields were removed.
  Run `wallpaper-theme` once to generate the new configs. Reopen Lazydocker once
  to adopt them; it has no live config reload in 0.25.2. Lazygit 0.65.0 can adopt
  its config when terminal focus returns, or on restart. Afterwards palette
  changes need neither restart nor focus changes in terminals covered below.
  This covers configured UI colors, not truecolor output from subprocesses.
  Other terminals need their own palette update mechanism.
- Foot and Ghostty receive OSC palette, foreground, background, cursor and
  selection updates through their outer PTYs, including terminals hosting tmux.
  Only terminal processes and devices owned by the current user are targeted.
- Fish's universal theme-change variable triggers shell color reload and an idle
  prompt repaint, including Starship. `fish --no-config` must not be used to send
  this event: it disables universal-variable persistence in the installed Fish.
- Pi watches `~/.pi/agent/themes/matugen.json`. It does not watch external cache
  theme paths. Run `/reload` once after this migration; choose `matugen` in
  `/settings` if needed. Later palette changes reload natively.
- Quickshell watches generated palette JSON. Wallpaper persistence uses
  `FileView.setText()`; there is no `writeFile()` method.

Already-open Fish sessions need to load the updated handler once:

```fish
source ~/.config/fish/functions/wallpaper_cli_reload.fish
wallpaper_cli_reload
```

Terminal palette changes cannot recolor truecolor text already printed into
scrollback. Application-specific truecolor UI needs its own redraw or theme
watcher. No keys or shell commands are injected into running terminals.

Checks:

```sh
python3 config/theme/check.py
python3 config/theme/test-ghostty.py
sh config/quickshell/scripts/test-theme.sh
```

Capability sources checked against installed app versions:

- [Ghostty runtime CSS and config reload](https://github.com/ghostty-org/ghostty/blob/v1.3.1/src/apprt/gtk/class/application.zig)
- [Lazygit focus-triggered reload](https://github.com/jesseduffield/lazygit/blob/v0.65.0/pkg/gui/gui.go)
- [Lazydocker supported theme fields](https://github.com/jesseduffield/lazydocker/blob/v0.25.2/pkg/config/app_config.go)
- [Lazydocker ANSI and reverse attributes](https://github.com/jesseduffield/lazydocker/blob/v0.25.2/pkg/gui/gocui.go)

Checks use temporary palettes and PTYs. They verify static ANSI app themes,
Ghostty's window theme setting, color delivery, no shell-input
injection, Ghostty reload arguments, idle Starship repaint without a keypress,
and Quickshell palette watching. They do not signal or recolor live terminals.
