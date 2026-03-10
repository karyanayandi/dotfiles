#!/bin/bash
# Generate fzf theme files for all vivid themes

DOTFILES_DIR="$HOME/.config/dotfiles"
VIVID_DIR="$DOTFILES_DIR/config/vivid"
THEMES_DIR="$DOTFILES_DIR/themes"

# Function to get color from vivid yaml
get_vivid_color() {
    local file="$1"
    local color_name="$2"
    grep -E "^  ${color_name}:" "$file" | head -1 | sed 's/.*: "\?\([^"]*\)"\?.*/\1/'
}

# Function to generate fzf colors for a theme
generate_fzf_theme() {
    local theme_name="$1"
    local vivid_file="$VIVID_DIR/${theme_name}.yaml"
    local fzf_dir="$THEMES_DIR/$theme_name/fzf"
    
    if [[ ! -f "$vivid_file" ]]; then
        echo "Skipping $theme_name: vivid file not found"
        return
    fi
    
    mkdir -p "$fzf_dir"
    
    # Extract colors from vivid
    local bg fg highlight active blue cyan green red yellow
    
    # Get basic colors from vivid color definitions
    bg=$(get_vivid_color "$vivid_file" "color0")
    fg=$(get_vivid_color "$vivid_file" "color4")
    highlight=$(get_vivid_color "$vivid_file" "color2")
    active=$(get_vivid_color "$vivid_file" "color1")
    blue=$(get_vivid_color "$vivid_file" "color10")
    cyan=$(get_vivid_color "$vivid_file" "color8")
    green=$(get_vivid_color "$vivid_file" "color14")
    red=$(get_vivid_color "$vivid_file" "color11")
    yellow=$(get_vivid_color "$vivid_file" "color13")
    
    # Add # prefix if missing
    [[ "$bg" != \#* ]] && bg="#$bg"
    [[ "$fg" != \#* ]] && fg="#$fg"
    [[ "$highlight" != \#* ]] && highlight="#$highlight"
    [[ "$active" != \#* ]] && active="#$active"
    [[ "$blue" != \#* ]] && blue="#$blue"
    [[ "$cyan" != \#* ]] && cyan="#$cyan"
    [[ "$green" != \#* ]] && green="#$green"
    [[ "$red" != \#* ]] && red="#$red"
    [[ "$yellow" != \#* ]] && yellow="#$yellow"
    
    # Build fzf color string
    local fzf_colors="--color=bg:${bg},fg:${fg},hl:${highlight},bg+:${active},fg+:${fg},hl+:${blue},info:${cyan},prompt:${blue},pointer:${red},marker:${green},spinner:${yellow},header:${yellow}"
    
    # Generate bash file (overwrite completely)
    cat > "$fzf_dir/colors.sh" << EOF
# FZF colors for ${theme_name} theme
# Auto-generated from vivid theme
export FZF_DEFAULT_OPTS="${fzf_colors}"
EOF
    
    # Generate fish file (overwrite completely)
    cat > "$fzf_dir/colors.fish" << EOF
# FZF colors for ${theme_name} theme
# Auto-generated from vivid theme
set -gx FZF_DEFAULT_OPTS "${fzf_colors}"
EOF
    
    echo "Generated fzf theme for $theme_name"
}

# Generate for all vivid themes
for vivid_file in "$VIVID_DIR"/*.yaml; do
    theme_name=$(basename "$vivid_file" .yaml)
    generate_fzf_theme "$theme_name"
done

echo "All fzf themes generated!"
