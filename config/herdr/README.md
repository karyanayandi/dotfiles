# Herdr shortcuts

The config uses `Ctrl+Space` as the prefix. Release it before the next key.
Tmux files remain unchanged. Herdr workspaces replace tmux sessions in these
bindings. Herdr tabs replace tmux windows.

| Action | Direct key | After prefix |
| --- | --- | --- |
| Settings | Ctrl+, | Shift+s |
| New workspace | Alt+Shift+n | Shift+n |
| Previous / next workspace | Alt+Shift+h / Alt+Shift+l | — |
| Select workspace 1–9 | Alt+Shift+1–9 | — |
| Help | Alt+? | ? |
| Detach | Alt+d | d |
| Reload config | Alt+r | Shift+r |
| Select workspace | Alt+m, Alt+= | m, backslash |
| Rename workspace | Alt+, | , |
| New tab | Alt+w | w |
| Rename tab | Alt+. | . |
| Previous / next tab | Alt+h / Alt+l | — |
| Select tab 1–9 | Alt+1–9 | 1–9 |
| Focus pane | — | h / j / k / l |
| Split side by side | Alt+s | s |
| Split above and below | Alt+v | v |
| Close pane | Alt+x | x |
| Toggle Herdr sidebar | Alt+b | b |
| Shell popup | Alt+t | — |

Alt+b opens the Herdr sidebar, not the Workmux sidebar. The workspace picker
replaces the tmux-fzf session picker. It does not manage separate Herdr server
sessions. The help view replaces the tmux-fzf key list.

## Desktop app

Desktop uses `config/herdr-app/keys.json`. Stow links it to
`~/.config/herdr-app/keys.json`. The app reads changes while it runs.

The direct keys in the table also apply to Desktop, except Alt+r and Alt+t.
Desktop reads config changes without a reload key. Its config has no shell
popup command. Desktop uses Alt+: for its command palette.
Alt+d closes the Desktop window; core terminals keep running.
Desktop has no documented tmux-style prefix mode. Use its direct keys.
The existing copy, paste, search, and other default keys stay in place,
except where a shared shortcut replaces them. Alt+1–9 now selects tabs,
not workspaces. Alt+h/l now selects tabs, not panes. Alt+Shift+h/l now
selects workspaces, not pane swaps.

## Vim navigation

Ctrl+h/j/k/l moves between Neovim splits. At an edge, it moves to the next
Herdr pane. Outside Herdr, the same keys still use `vim-tmux-navigator`.
Ctrl+backslash keeps the tmux previous-pane action. Editor maps use normal mode.

Install the CLI plugin once:

```sh
herdr plugin install paulbkim-dev/vim-herdr-navigation --yes
```

Neovim installs the same repository through lazy.nvim and loads its editor
maps. Keep `jq` installed so the CLI plugin can detect Vim.

Desktop uses the local `vim-navigation` mod. Stow
`herdr-app/mods/vim-navigation/` and select `matugen` or `matugen-herdr`.
These layouts load the mod without a visible panel. Other layouts need the
same `floating` entry. The mod checks the focused terminal's foreground
program with `hc get`, forwards Vim keys with `hc keys`, and uses `pane.go`
for other programs. Keep the `hc` CLI installed.

These bindings replace shell Ctrl+L (clear screen), Ctrl+K (kill line),
Ctrl+H (backspace on some terminals), and Ctrl+J (line feed). Use the existing
Alt/prefix keys to leave programs that capture these keys. Tmux files do not
change. If tmux runs inside Herdr, Herdr is the outer navigation target.

## Limits

- Herdr tab shortcuts use indexes 1–9. There is no tmux-style tab 0 binding.
- Alt+: has no tmux command prompt in Herdr.
- Alt+o, Alt+p, prefix+o, and prefix+p are not mapped. The Workmux menu and
  dashboard use tmux commands. Do not call them from these Herdr bindings.
- Prefix+Ctrl+f has no combined tmux-fzf menu. Use the workspace picker or help.
- TPM install/update keys, tmux-resurrect save/restore keys, and tmux-yank copy
  keys do not apply to Herdr. Herdr manages its own persistent sessions and
  clipboard support.
- Prefix+Ctrl+Space is not configured as tmux `send-prefix`.
- Wallpaper colors now apply to Herdr through Matugen. Edit `base.toml` for
  keys and settings. Do not edit the generated `config.toml`.

The outer terminal and window manager must pass Alt keys to Herdr. If Herdr
runs inside tmux with the old config, tmux can capture those keys first.

## Apply and check

The dotfiles setup uses `stow` from `config/` with `~/.config` as its target.
Check the config with `herdr config check`. Apply changes to a running server
with `herdr server reload-config`.

## Wallpaper colors

Run `wallpaper-theme` after you change `base.toml`. Matugen adds the color
settings and writes `~/.config/theme/generated/herdr.toml`. `config.toml`
links to this file. The wallpaper command reloads a running default Herdr
server. Named sessions need `herdr --session NAME server reload-config`.

Desktop has two Matugen layouts. Stow the files in `herdr-app/layouts/`
and `herdr-app/mods/matugen-terminals-bar/`. Both layouts use
`~/.config/herdr-app/themes/matugen.json`. The Terminals layout uses the
local tab bar mod. It uses icons from the installed `terminals-bar` mod.

| Layout | Structure |
| --- | --- |
| `matugen-herdr` | Default Herdr: spaces and agents sidebar, tabs, Files and Changes panels, status bar |
| `matugen` | Terminals: tabs in the title bar and terminal panes |

Select the default Herdr version:

```sh
herdr-app do layout.switch --name matugen-herdr
```

Select the Terminals version:

```sh
herdr-app do layout.switch --name matugen
```

Desktop watches the generated theme file. Later wallpaper changes need no
restart. Both layouts use color names, not fixed hex colors. The original
layouts stay unchanged.
Other layouts can use the theme through `herdr-app do app.theme --name matugen`;
fixed layout colors can still override theme colors.
