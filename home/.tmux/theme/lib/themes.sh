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
"aurora")
  declare -A THEME=(
    ["background"]="#282c34"
    ["foreground"]="#c8ccd4"
    ["highlight"]="#3e4451"
    ["active"]="#353b45"
    ["blue"]="#5e81ac"
    ["cyan"]="#8fbcbb"
    ["green"]="#a3be8c"
    ["red"]="#bf616a"
    ["yellow"]="#ebcb8b"
  )
  ;;

"onedark")
  declare -A THEME=(
    ["background"]="#282c34"
    ["foreground"]="#abb2bf"
    ["highlight"]="#31353f"
    ["active"]="#3b3f4c"
    ["blue"]="#61afef"
    ["cyan"]="#56b6c2"
    ["green"]="#98c379"
    ["red"]="#e86671"
    ["yellow"]="#e5c07b"
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

"gruvbox-dark-medium")
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

"gruvbox-dark-medium-monochrome")
  declare -A THEME=(
    ["background"]="#282828"
    ["foreground"]="#bdae93"
    ["highlight"]="#3c3836"
    ["active"]="#504945"
    ["blue"]="#928374"
    ["cyan"]="#a89984"
    ["green"]="#928374"
    ["red"]="#bdae93"
    ["yellow"]="#bdae93"
  )
  ;;

"nord")
  declare -A THEME=(
    ["background"]="#2e3440"
    ["foreground"]="#d8dee9"
    ["highlight"]="#4c566a"
    ["active"]="#3b4252"
    ["blue"]="#81a1c1"
    ["cyan"]="#88c0d0"
    ["green"]="#a3be8c"
    ["red"]="#bf616a"
    ["yellow"]="#ebcb8b"
  )
  ;;

"lackluster")
  declare -A THEME=(
    ["background"]="#0A0A0A"
    ["foreground"]="#DEEEED"
    ["highlight"]="#444444"
    ["active"]="#7A7A7A"
    ["blue"]="#7788AA"
    ["cyan"]="#708090"
    ["green"]="#789978"
    ["red"]="#D70000"
    ["yellow"]="#FFAA88"
  )
  ;;

"rosepine")
  declare -A THEME=(
    ["background"]="#191724"
    ["foreground"]="#e0def4"
    ["highlight"]="#26233a"
    ["active"]="#1f1d2e"
    ["blue"]="#31748f"
    ["cyan"]="#9ccfd8"
    ["green"]="#9ccfd8"
    ["red"]="#eb6f92"
    ["yellow"]="#f6c177"
  )
  ;;

"vesper")
  declare -A THEME=(
    ["background"]="#101010"
    ["foreground"]="#FFFFFF"
    ["highlight"]="#1C1C1C"
    ["active"]="#161616"
    ["blue"]="#99D1FF"
    ["cyan"]="#99FFE4"
    ["green"]="#99FFE4"
    ["red"]="#FF8080"
    ["yellow"]="#FFD580"
  )
  ;;

*)
  declare -A THEME=(
    ["background"]="#2e3440"
    ["foreground"]="#d8dee9"
    ["highlight"]="#4c566a"
    ["active"]="#3b4252"
    ["blue"]="#81a1c1"
    ["cyan"]="#88c0d0"
    ["green"]="#a3be8c"
    ["red"]="#bf616a"
    ["yellow"]="#ebcb8b"
  )
  ;;
esac

RESET="#\[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim\]"
