function search_text
    ~/.local/bin/search-text.sh
end

function fish_user_key_bindings
    bind -M insert \ct search_text
    bind -M default \ct search_text
end

fish_user_key_bindings
