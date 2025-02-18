set fish_greeting ''

starship init fish | source
export STARSHIP_CONFIG=/home/karyana/.config/starship/starship.toml

# Environment
export TERM=screen-256color
export EDITOR=nvim
export SHELL=/usr/bin/fish
export LANG=en_US.utf8
export LC_COLLATE=C
export LC_ADDRESS=en_US.utf8
export LC_CTYPE=en_US.utf8
export LC_IDENTIFICATION=en_US.utf8
export LC_MEASUREMENT=en_US.utf8
export LC_MESSAGES=en_US.utf8
export LC_MONETARY=en_US.utf8
export LC_NAME=en_US.utf8
export LC_NUMERIC=en_US.utf8
export LC_PAPER=en_US.utf8
export LC_TELEPHONE=en_US.utf8
export LC_TIME=en_US.utf8

## Aliases
alias autoclean "sudo pacman -R $(pacman -Qdtq)"
alias bn bun
alias bx bunx
alias c clear
alias cat bat
alias cdc "cd ~/.config/dotfiles"
alias cdp "cd ~/Codes"
alias cl clear
alias clean-code "find . -type d -name 'node_modules' -o -name '.next' -o -name '.turbo' -exec rm -rf {} + -o -type f -name '*.astro' -exec rm -f {} +;"
alias clean "yay -Yc"
alias d "yay -Rns"
alias dbox distrobox
alias delete "yay -Rns"
alias docker podman
alias e nvim
alias eb "nvim ~/.bashrc"
alias ef "nvim ~/config/fish/config.fish"
alias en "nvim ~/.config/nvim/init.lua"
alias es "nvim ~/.config/sway/config"
alias exp "gh copilot explain"
alias ez "nvim ~/.zshrc"
alias font-list "fc-list : family"
alias font-refresh "fc-cache -fv"
alias g git
alias i "yay -S"
alias install "yay -S"
alias ll "eza -al -g --icons"
alias ls "eza --group-directories-first --icons"
alias lsl "eza --group-directories-first -lh --icons"
alias lzg lazygit
alias npm "corepack npm"
alias npx "corepack npx"
alias pac "sudo pacman -S"
alias pkglist "yay -Qe"
alias pn "corepack pnpm"
alias pnpm "corepack pnpm"
alias pnpx "corepack pnpx"
alias px "corepack pnpx"
alias refresh-mirror "sudo reflector --latest 5 --protocol https --country 'Singapore' --sort rate --save /etc/pacman.d/mirrorlist"
alias rm trash-put
alias rmr rm
alias s "yay -s"
alias search "yay -s"
alias sug "gh copilot suggest"
alias t tmux
alias tree "exa --tree --group-directories-first --icons --ignore-glob '*node_modules*'"
alias u "yay -Syyu"
alias update-time "sudo ntpd -qg"
alias update "yay -Syyu"
alias vim nvim
alias vis "sudo nvim"
alias x exit
alias yarn "corepack yarn"
alias yarnpkg "corepack yarnpkg"

## Keybinding
set fish_key_bindings fish_default_key_bindings

#pnpm
set -gx PNPM_HOME "$HOME/.local/share/pnpm"
set -gx PATH "$PNPM_HOME" $PATH

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

#fzf
export FZF_DEFAULT_COMMAND='find .'
