# Live wallpaper colors

`~/.local/bin/wallpaper-theme` renders colors, then refreshes running consumers.

- GTK3 alternates generated `matugen-dark` themes through GSettings after each
  render. Colors belong to the named theme, not the startup-only user CSS.
  Log out/in once to drop the old `GTK_THEME` override and cached user CSS.
  GTK4/libadwaita still uses generated user CSS and needs an app restart;
  there is no universal external CSS-reload API. X11 apps also need a desktop
  settings bridge that forwards GSettings to XSettings.
- Qt5/Qt6 apps using qt5ct/qt6ct reload about 3 seconds after a temporary entry
  is created and removed in their config directory. Touching a symlinked config
  target does not notify this directory watcher.
  Apps using another platform theme or their own palette are not covered.
- Ghostty reloads its app config with `SIGUSR2`, so new windows also inherit the
  new palette. Only processes with a registered signal handler receive it.
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
sh config/quickshell/scripts/test-theme.sh
```

Checks use temporary palettes and PTYs. They verify color delivery, no shell-input
injection, Ghostty reload arguments, idle Starship repaint without a keypress,
and Quickshell palette watching. They do not signal or recolor live terminals.
