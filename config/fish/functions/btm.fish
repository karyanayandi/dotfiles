function btm --wraps btm
    set -l config "$HOME/.config/theme/generated/bottom.toml"
    if test -f "$config"
        command btm --config_location "$config" $argv
    else
        command btm $argv
    end
end
