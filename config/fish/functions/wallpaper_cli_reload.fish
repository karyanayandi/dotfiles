function wallpaper_cli_reload --on-variable wallpaper_theme_generation --description 'Load generated wallpaper colors'
    set -l generated "$HOME/.config/theme/generated"
    if test -f "$generated/fish.fish"
        source "$generated/fish.fish"
    end
    if test -f "$generated/vivid.yaml"; and command -q vivid
        set -gx LS_COLORS (vivid generate "$generated/vivid.yaml")
    end
    if test -f "$generated/lazygit.yml"
        set -gx LG_CONFIG_FILE "$HOME/.config/lazygit/config.yml,$generated/lazygit.yml"
    end
    set -gx STARSHIP_CONFIG "$HOME/.config/starship/starship.toml"
    if test -f "$generated/starship.toml"
        set -gx STARSHIP_CONFIG "$generated/starship.toml"
    end
    # Universal-variable events can arrive while the reader is idle.
    if status is-interactive; and test "$argv[1]" = VARIABLE
        commandline -f repaint
    end
end
