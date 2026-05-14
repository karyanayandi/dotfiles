#!/usr/bin/env bash

# Get theme from environment variable, tmux option, or default to nord
if [[ -n "$THEME_NAME" ]]; then
  SELECTED_THEME="$THEME_NAME"
elif tmux show-option -gv @themes &>/dev/null; then
  SELECTED_THEME=$(tmux show-option -gv @themes)
else
  SELECTED_THEME="nord"
fi

case $SELECTED_THEME in
"gruvbox-dark-hard")
  declare -A THEME=(
    ["background"]="#1d2021"
    ["foreground"]="#ebdbb2"
    ["highlight"]="#504945"
    ["active"]="#3c3836"
    ["blue"]="#83a598"
    ["cyan"]="#8ec07c"
    ["green"]="#b8bb26"
    ["red"]="#fb4934"
    ["yellow"]="#fabd2f"
  )
  ;;

"gruvbox-dark-hard-monochrome")
  declare -A THEME=(
    ["background"]="#1d2021"
    ["foreground"]="#bdae93"
    ["highlight"]="#32302f"
    ["active"]="#45403d"
    ["blue"]="#928374"
    ["cyan"]="#a89984"
    ["green"]="#928374"
    ["red"]="#bdae93"
    ["yellow"]="#bdae93"
  )
  ;;

*)
  declare -A THEME=(
    ["background"]="#1d2021"
    ["foreground"]="#ebdbb2"
    ["highlight"]="#504945"
    ["active"]="#3c3836"
    ["blue"]="#83a598"
    ["cyan"]="#8ec07c"
    ["green"]="#b8bb26"
    ["red"]="#fb4934"
    ["yellow"]="#fabd2f"
  )
  ;;
esac

RESET="#\[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim\]"
