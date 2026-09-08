# Live wallpaper colors

`~/.local/bin/wallpaper-theme` renders colors, then refreshes running consumers.

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
