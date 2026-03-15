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

"catppuccin-mocha")
  declare -A THEME=(
    ["background"]="#1e1e2e"
    ["foreground"]="#cdd6f4"
    ["highlight"]="#313244"
    ["active"]="#45475a"
    ["blue"]="#89b4fa"
    ["cyan"]="#94e2d5"
    ["green"]="#a6e3a1"
    ["red"]="#f38ba8"
    ["yellow"]="#f9e2af"
  )
  ;;

"everforest-hard")
  declare -A THEME=(
    ["background"]="#2b3339"
    ["foreground"]="#d3c6aa"
    ["highlight"]="#3a4248"
    ["active"]="#4a5258"
    ["blue"]="#7fbbb3"
    ["cyan"]="#83c092"
    ["green"]="#a7c080"
    ["red"]="#e67e80"
    ["yellow"]="#dbbc7f"
  )
  ;;

"everforest-medium")
  declare -A THEME=(
    ["background"]="#2f383e"
    ["foreground"]="#d3c6aa"
    ["highlight"]="#3a4248"
    ["active"]="#4a5258"
    ["blue"]="#7fbbb3"
    ["cyan"]="#83c092"
    ["green"]="#a7c080"
    ["red"]="#e67e80"
    ["yellow"]="#dbbc7f"
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

"gruvbox-light-hard")
  declare -A THEME=(
    ["background"]="#f9f5d7"
    ["foreground"]="#3c3836"
    ["highlight"]="#ebdbb2"
    ["active"]="#d5c4a1"
    ["blue"]="#076678"
    ["cyan"]="#427b58"
    ["green"]="#79740e"
    ["red"]="#9d0006"
    ["yellow"]="#b57614"
  )
  ;;

"rosepine-dawn")
  declare -A THEME=(
    ["background"]="#faf4ed"
    ["foreground"]="#575279"
    ["highlight"]="#f2e9e1"
    ["active"]="#fffaf3"
    ["blue"]="#56949f"
    ["cyan"]="#9ccfd8"
    ["green"]="#286983"
    ["red"]="#b4637a"
    ["yellow"]="#ea9d34"
  )
  ;;

"tokyo-night-moon")
  declare -A THEME=(
    ["background"]="#222436"
    ["foreground"]="#c8d3f5"
    ["highlight"]="#2f334d"
    ["active"]="#1e2030"
    ["blue"]="#82aaff"
    ["cyan"]="#86e1fc"
    ["green"]="#c3e88d"
    ["red"]="#ff757f"
    ["yellow"]="#ffc777"
  )
  ;;

"tokyo-night-storm")
  declare -A THEME=(
    ["background"]="#24283b"
    ["foreground"]="#c0caf5"
    ["highlight"]="#2e3c64"
    ["active"]="#1f2335"
    ["blue"]="#7aa2f7"
    ["cyan"]="#7dcfff"
    ["green"]="#9ece6a"
    ["red"]="#f7768e"
    ["yellow"]="#e0af68"
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
