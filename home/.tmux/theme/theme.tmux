#!/usr/bin/env bash
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_PATH="$CURRENT_DIR/lib"

source $SCRIPTS_PATH/themes.sh

# Persist the theme in tmux option
tmux set -g @themes "$SELECTED_THEME"

tmux set -g status-left-length 80
tmux set -g status-right-length 150

RESET="#[fg=${THEME[foreground]},bg=${THEME[highlight]},nobold,noitalics,nounderscore,nodim]"

tmux set -g mode-style "fg=${THEME[green]},bg=${THEME[active]}"
tmux set -g message-style "bg=${THEME[blue]},fg=${THEME[background]}"
tmux set -g message-command-style "fg=${THEME[foreground]},bg=${THEME[active]}"
tmux set -g pane-border-style "fg=${THEME[active]}"
tmux set -g pane-active-border-style "fg=${THEME[blue]}"
tmux set -g pane-border-status off
tmux set -g status-style bg="${THEME[background]}"

# Popup/float menu styles (for tmux-fzf and other popups)
tmux set -g popup-style "fg=${THEME[foreground]},bg=${THEME[background]}"
tmux set -g popup-border-style "fg=${THEME[active]}"
tmux set -g popup-border-lines single

# Menu style (for right-click context menus)
tmux set -g menu-style "fg=${THEME[foreground]},bg=${THEME[background]}"
tmux set -g menu-border-style "fg=${THEME[active]}"
tmux set -g menu-selected-style "fg=${THEME[background]},bg=${THEME[blue]}"

zoom_number="#($SCRIPTS_PATH/number.sh #P)"

## Left Bars
tmux set -g status-left "#[fg=${THEME[highlight]},bg=${THEME[cyan]},bold] #{?client_prefix,󰠠 ,#[dim]󰤂 }#[bold,nodim]#S "

# Focus Window
tmux set -g window-status-current-format "$RESET#[fg=${THEME[yellow]},bg=${THEME[active]}] #{?#{==:#{pane_current_command},ssh},󰣀,} #[fg=${THEME[foreground]},bold,nodim]#W#[nobold]#{?window_zoomed_flag, $zoom_number, $custom_pane} #{?window_last_flag,,} "
# Unfocused Window
tmux set -g window-status-format "$RESET#[fg=${THEME[foreground]}] #{?#{==:#{pane_current_command},ssh},󰣀,}${RESET} #W#[nobold,dim]#{?window_zoomed_flag, $zoom_number, $custom_pane} #[fg=${THEME[yellow]}]#{?window_last_flag,, }"

# Right Bars
tmux set -g status-right ""
tmux set -g window-status-separator ""
