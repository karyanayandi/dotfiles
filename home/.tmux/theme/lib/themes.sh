#!/usr/bin/env bash

SELECTED_THEME="${THEME_NAME:-$(tmux -L "$(tmux list-sessions -F '#{session_name}' | head -1)" show-option -gv @themes 2>/dev/null || echo "")}"
SELECTED_THEME="${SELECTED_THEME:-nord-light}"

case $SELECTED_THEME in
"aurora")
  declare -A THEME=(
    ["background"]="#282c34"
    ["foreground"]="#d8dee9"
    ["highlight"]="#3e4451"
    ["active"]="#353b45"
    ["blue"]="#5e81ac"
    ["cyan"]="#88c0d0"
    ["green"]="#a3be8c"
    ["red"]="#bf616a"
    ["yellow"]="#ebcb8b"
  )
  ;;

"onedark")
  declare -A THEME=(
    ["background"]="#282c34"
    ["foreground"]="#c8ccd4"
    ["highlight"]="#3e4451"
    ["active"]="#353b45"
    ["blue"]="#61afef"
    ["cyan"]="#56b6c2"
    ["green"]="#98c379"
    ["red"]="#be5046"
    ["yellow"]="#e5c07b"
  )
  ;;

"onenord")
  declare -A THEME=(
    ["background"]="#282c34"
    ["foreground"]="#c8ccd4"
    ["highlight"]="#3e4451"
    ["active"]="#353b45"
    ["blue"]="#81A1C1"
    ["cyan"]="#88C0D0"
    ["green"]="#A3BE8C"
    ["red"]="#D57780"
    ["yellow"]="#EBCB8B"
  )
  ;;

"nord-dark")
  declare -A THEME=(
    ["background"]="#2E3440"
    ["foreground"]="#C8D0E0"
    ["highlight"]="#4C566A"
    ["active"]="#3B4252"
    ["blue"]="#81A1C1"
    ["cyan"]="#88C0D0"
    ["green"]="#A3BE8C"
    ["red"]="#D57780"
    ["yellow"]="#EBCB8B"
  )
  ;;

"nord-light")
  declare -A THEME=(
    ["background"]="#EFF0F2"
    ["foreground"]="#4C566A"
    ["highlight"]="#D8DEE9"
    ["active"]="#2E3440"
    ["blue"]="#3879C5"
    ["cyan"]="#3EA1AD"
    ["green"]="#48A53D"
    ["red"]="#CB4F53"
    ["yellow"]="#BA793E"
  )
  ;;

"catppuccin-mocha")
  declare -A THEME=(
    ["background"]="#1e1e2e"
    ["foreground"]="#cdd6f4"
    ["highlight"]="#9399b2"
    ["active"]="#7f849c"
    ["blue"]="#89b4fa"
    ["cyan"]="#74c7ec"
    ["green"]="#a6e3a1"
    ["red"]="#f38ba8"
    ["yellow"]="#f9e2af"
  )
  ;;

"gruvbox-dark")
  declare -A THEME=(
    ["background"]="#282828"
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

"gruvbox-light")
  declare -A THEME=(
    ["background"]="#fbf1c7"
    ["foreground"]="#3c3836"
    ["highlight"]="#d5c4a1"
    ["active"]="#ebdbb2"
    ["blue"]="#076678"
    ["cyan"]="#427b58"
    ["green"]="#79740e"
    ["red"]="#9d0006"
    ["yellow"]="#d79921"
  )
  ;;

*)
  declare -A THEME=(
    ["background"]="#282c34"
    ["foreground"]="#d8dee9"
    ["highlight"]="#3e4451"
    ["active"]="#353b45"
    ["blue"]="#5e81ac"
    ["cyan"]="#88c0d0"
    ["green"]="#a3be8c"
    ["red"]="#bf616a"
    ["yellow"]="#ebcb8b"
  )
  ;;
esac

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"
