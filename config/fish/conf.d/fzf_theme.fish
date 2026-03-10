#!/usr/bin/env fish
# FZF theme auto-reloader for fish
# Sources fzf colors on every prompt if they changed

function __fzf_reload_theme --on-event fish_prompt
    # Source fzf colors if file exists
    if test -f ~/.config/fzf/colors.fish
        source ~/.config/fzf/colors.fish
    end
end

# Initial load
if test -f ~/.config/fzf/colors.fish
    source ~/.config/fzf/colors.fish
end