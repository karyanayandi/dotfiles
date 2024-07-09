set fish_greeting ''

alias c clear
alias g git
alias ls "exa --group-directories-first --icons"
alias lsl "exa --group-directories-first -lh --icons"
alias ll "exa -al -g --icons"
alias tree "exa --tree --group-directories-first --icons --ignore-glob='*node_modules*'"
alias x exit

starship init fish | source
