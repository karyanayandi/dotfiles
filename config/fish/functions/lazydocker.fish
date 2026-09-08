function lazydocker --wraps lazydocker
    set -l config "$HOME/.config/theme/generated/lazydocker"
    if test -f "$config/config.yml"
        env CONFIG_DIR="$config" lazydocker $argv
    else
        command lazydocker $argv
    end
end
