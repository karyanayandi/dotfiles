#!/bin/bash

set -e

# Waybar, Foot, Bat, and Bottom Theme Switcher
# Automatically discover and switch between themes for waybar, foot terminal, bat, and bottom
# Usage: theme-switch.sh [theme-name]

# Dotfiles directory
DOTFILES_DIR="$HOME/.config/dotfiles"
THEMES_DIR="$DOTFILES_DIR/themes"
CURRENT_THEME_DIR="$THEMES_DIR/current"

# Track which components were updated
UPDATED_COMPONENTS=()

# Display help text
show_help() {
  echo "Usage: theme-switch.sh [THEME_NAME]"
  echo ""
  echo "Switch themes for waybar, foot terminal, bat, and bottom with real-time reload."
  echo ""
  echo "Options:"
  echo "  -h, --help    Show this help message"
  echo ""
  echo "Examples:"
  echo "  theme-switch.sh            # Interactive selection"
  echo "  theme-switch.sh aurora     # Switch to aurora theme"
  echo "  theme-switch.sh gruvbox    # Switch to gruvbox theme"
  echo ""
  echo "Available themes:"
  discover_themes
  for theme in "${AVAILABLE_THEMES[@]}"; do
    echo "  - $theme"
  done
}

# Discover available themes
discover_themes() {
  AVAILABLE_THEMES=()

  # Scan themes directory for valid themes
  if [[ ! -d "$THEMES_DIR" ]]; then
    echo "Error: Themes directory not found at $THEMES_DIR" >&2
    exit 1
  fi

  for theme_dir in "$THEMES_DIR"/*/; do
    local discovered_theme=$(basename "$theme_dir")

    # Skip 'current' directory (it's our symlink target)
    if [[ "$discovered_theme" == "current" ]]; then
      continue
    fi

    # Check if theme has required files (waybar, foot, bat, or bottom)
    local has_waybar=false
    local has_foot=false
    local has_bat=false
    local has_bottom=false
    
    if [[ -f "$theme_dir/waybar/waybar.css" ]]; then
      has_waybar=true
    fi
    
    if [[ -f "$theme_dir/foot/colors.ini" ]]; then
      has_foot=true
    fi
    
    if [[ -f "$theme_dir/bat/config" ]]; then
      has_bat=true
    fi
    
    if [[ -f "$theme_dir/bottom/bottom.toml" ]]; then
      has_bottom=true
    fi
    
    # Theme is valid if it has at least one component
    if [[ "$has_waybar" == true || "$has_foot" == true || "$has_bat" == true || "$has_bottom" == true ]]; then
      AVAILABLE_THEMES+=("$discovered_theme")
    fi
  done

  if [[ ${#AVAILABLE_THEMES[@]} -eq 0 ]]; then
    echo "Error: No valid themes found in $THEMES_DIR" >&2
    echo "Themes must have waybar/waybar.css, foot/colors.ini, bat/config, or bottom/bottom.toml" >&2
    exit 1
  fi
}

# Validate theme exists
validate_theme() {
  local theme_name="$1"

  for theme in "${AVAILABLE_THEMES[@]}"; do
    if [[ "$theme" == "$theme_name" ]]; then
      return 0
    fi
  done

  return 1
}

# Interactive theme selection
select_theme_interactive() {
  # Try fzf first
  if command -v fzf &>/dev/null; then
    local selected
    selected=$(printf '%s\n' "${AVAILABLE_THEMES[@]}" | fzf --prompt="Select theme: " --height=40% --border)

    # Check if user cancelled (fzf returns empty on cancel)
    if [[ -z "$selected" ]]; then
      echo "Theme selection cancelled." >&2
      exit 0
    fi

    echo "$selected"
  else
    # Fallback to numbered list
    echo "Available themes:"
    for i in "${!AVAILABLE_THEMES[@]}"; do
      echo "  $((i + 1)). ${AVAILABLE_THEMES[$i]}"
    done

    echo ""
    read -p "Select theme (number or name): " selection

    # Check if selection is a number
    if [[ "$selection" =~ ^[0-9]+$ ]]; then
      local index=$((selection - 1))
      if [[ $index -ge 0 && $index -lt ${#AVAILABLE_THEMES[@]} ]]; then
        echo "${AVAILABLE_THEMES[$index]}"
      else
        echo "Error: Invalid selection" >&2
        exit 1
      fi
    else
      # Selection is a name
      echo "$selection"
    fi
  fi
}

# Update waybar theme symlink
update_waybar_theme() {
  local theme_name="$1"
  local source_css="$THEMES_DIR/$theme_name/waybar/waybar.css"
  
  # Check if theme has waybar support
  if [[ ! -f "$source_css" ]]; then
    echo "Note: Theme '$theme_name' does not have waybar support, skipping."
    return 0
  fi
  
  local target_dir="$CURRENT_THEME_DIR/waybar"
  local target_css="$target_dir/waybar.css"

  # Create target directory if it doesn't exist
  if [[ ! -d "$target_dir" ]]; then
    mkdir -p "$target_dir"
  fi

  # Create relative symlink (../../theme/waybar/waybar.css)
  local relative_path="../../$theme_name/waybar/waybar.css"

  # Update symlink atomically
  ln -sf "$relative_path" "$target_css"

  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to update waybar symlink at $target_css" >&2
    exit 1
  fi
  
  UPDATED_COMPONENTS+=("waybar")
}

# Update foot theme symlink
update_foot_theme() {
  local theme_name="$1"
  local source_ini="$THEMES_DIR/$theme_name/foot/colors.ini"
  
  # Check if theme has foot support
  if [[ ! -f "$source_ini" ]]; then
    echo "Note: Theme '$theme_name' does not have foot support, skipping."
    return 0
  fi
  
  local target_dir="$CURRENT_THEME_DIR/foot"
  local target_ini="$target_dir/colors.ini"

  # Create target directory if it doesn't exist
  if [[ ! -d "$target_dir" ]]; then
    mkdir -p "$target_dir"
  fi

  # Create relative symlink (../../theme/foot/colors.ini)
  local relative_path="../../$theme_name/foot/colors.ini"

  # Update symlink atomically
  ln -sf "$relative_path" "$target_ini"

  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to update foot symlink at $target_ini" >&2
    exit 1
  fi
  
  UPDATED_COMPONENTS+=("foot")
}

# Update bat theme symlink
update_bat_theme() {
  local theme_name="$1"
  local source_config="$THEMES_DIR/$theme_name/bat/config"
  
  # Check if theme has bat support
  if [[ ! -f "$source_config" ]]; then
    echo "Note: Theme '$theme_name' does not have bat support, skipping."
    return 0
  fi
  
  local target_dir="$CURRENT_THEME_DIR/bat"
  local target_config="$target_dir/config"

  # Create target directory if it doesn't exist
  if [[ ! -d "$target_dir" ]]; then
    mkdir -p "$target_dir"
  fi

  # Create relative symlink (../../theme/bat/config)
  local relative_path="../../$theme_name/bat/config"

  # Update symlink atomically
  ln -sf "$relative_path" "$target_config"

  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to update bat symlink at $target_config" >&2
    exit 1
  fi
  
  UPDATED_COMPONENTS+=("bat")
}

# Update bottom theme symlink
update_bottom_theme() {
  local theme_name="$1"
  local source_toml="$THEMES_DIR/$theme_name/bottom/bottom.toml"
  
  # Check if theme has bottom support
  if [[ ! -f "$source_toml" ]]; then
    echo "Note: Theme '$theme_name' does not have bottom support, skipping."
    return 0
  fi
  
  local target_dir="$CURRENT_THEME_DIR/bottom"
  local target_toml="$target_dir/bottom.toml"

  # Create target directory if it doesn't exist
  if [[ ! -d "$target_dir" ]]; then
    mkdir -p "$target_dir"
  fi

  # Create relative symlink (../../theme/bottom/bottom.toml)
  local relative_path="../../$theme_name/bottom/bottom.toml"

  # Update symlink atomically
  ln -sf "$relative_path" "$target_toml"

  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to update bottom symlink at $target_toml" >&2
    exit 1
  fi
  
  UPDATED_COMPONENTS+=("bottom")
}

# Reload waybar
reload_waybar() {
  if pgrep -x waybar >/dev/null; then
    pkill -SIGUSR2 waybar
    if [[ $? -eq 0 ]]; then
      echo "  ✓ Waybar reloaded successfully"
    else
      echo "  ! Warning: Failed to reload waybar. You may need to restart it manually." >&2
    fi
  else
    echo "  - Waybar is not running. Theme will apply on next start."
  fi
}

# Reload foot terminals
reload_foot() {
  # Check if foot server is running (supports better reload)
  if pgrep -x foot --server >/dev/null 2>&1 || pgrep -f "foot.*--server" >/dev/null 2>&1; then
    echo "  - Foot server detected, restarting..."
    pkill -SIGHUP -f "foot.*--server"
    echo "  ✓ Foot server reloaded with new theme"
    return 0
  fi
  
  if pgrep -x foot >/dev/null; then
    local foot_count=$(pgrep -x foot | wc -l)
    echo "  - Found $foot_count running foot terminal(s)"
    echo "  - Foot theme updated (open new terminal to see changes)"
  else
    echo "  - Foot is not running. Theme will apply on next start."
  fi
}

# Reload bat cache
reload_bat() {
  echo "  - Rebuilding bat cache for new theme..."
  bat cache --build &>/dev/null
  if [[ $? -eq 0 ]]; then
    echo "  ✓ Bat cache rebuilt successfully"
  else
    echo "  ! Warning: Failed to rebuild bat cache" >&2
  fi
}

# Reload bottom
reload_bottom() {
  if pgrep -x btm >/dev/null; then
    echo "  - Bottom is running. Restart it to see theme changes."
    echo "    Tip: Press 'q' in bottom and reopen it"
  else
    echo "  - Bottom theme updated (will apply on next start)"
  fi
}

# Main function
main() {
  local theme_name=""

  # Parse arguments
  if [[ $# -gt 0 ]]; then
    case "$1" in
    -h | --help)
      show_help
      exit 0
      ;;
    *)
      theme_name="$1"
      ;;
    esac
  fi

  # Discover available themes
  discover_themes

  # If no theme specified, show interactive selection
  if [[ -z "$theme_name" ]]; then
    theme_name=$(select_theme_interactive)
  fi

  # Validate theme exists
  if ! validate_theme "$theme_name"; then
    echo "Error: Theme '$theme_name' not found or invalid." >&2
    echo "" >&2
    echo "Available themes:" >&2
    for theme in "${AVAILABLE_THEMES[@]}"; do
      echo "  - $theme" >&2
    done
    exit 1
  fi

  # Update themes
  echo "Switching to theme: $theme_name"
  echo ""
  
  # Update component themes
  update_waybar_theme "$theme_name"
  update_foot_theme "$theme_name"
  update_bat_theme "$theme_name"
  update_bottom_theme "$theme_name"
  
  # Check if any components were updated
  if [[ ${#UPDATED_COMPONENTS[@]} -eq 0 ]]; then
    echo "Error: Theme '$theme_name' does not support any components" >&2
    exit 1
  fi
  
  echo ""
  echo "Reloading components..."
  
  # Reload components that were updated
  for component in "${UPDATED_COMPONENTS[@]}"; do
    case "$component" in
      waybar)
        reload_waybar
        ;;
      foot)
        reload_foot
        ;;
      bat)
        reload_bat
        ;;
      bottom)
        reload_bottom
        ;;
    esac
  done
  
  echo ""
  echo "Theme switched successfully to $theme_name!"
}

# Run main function
main "$@"
