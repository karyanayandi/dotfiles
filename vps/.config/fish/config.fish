set fish_greeting ''

alias c clear
alias g git
alias ls "eza --group-directories-first --icons"
alias lsl "eza --group-directories-first -lh --icons"
alias ll "eza -al -g --icons"
alias tree "eza --tree --group-directories-first --icons --ignore-glob='*node_modules*'"
alias x exit

starship init fish | source
