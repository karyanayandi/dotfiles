# Initialize Starship prompt
eval "$(starship init zsh)"
export STARSHIP_CONFIG="$HOME/.config/starship.toml"

# Aliases
alias autoclean="sudo pacman -R $(pacman -Qdtq)"
alias c="clear"
alias cdc="cd ~/.config"
alias cdd="cd ~/Database"
alias cdo="cd ~/Downloads"
alias cdp="cd ~/Codes"
alias cl="clear"
alias clean="yay -Yc"
alias d="yay -Rns"
alias delete="yay -Rns"
alias docker="podman"
alias e="nvim"
alias eb "nvim ~/.bashrc"
alias en="nvim ~/.config/nvim/init.lua"
alias es="nvim ~/.config/sway/config"
alias exp="gh copilot explain"
alias ez="nvim ~/.zshrc"
alias font-refresh="fc-cache -fv"
alias g="git"
alias i="yay -S"
alias install="yay -S"
alias ll="eza -al -g --icons"
alias ls="eza --group-directories-first --icons"
alias lsl="eza --group-directories-first -lh --icons"
alias lzg="lazygit"
alias npm="corepack npm"
alias npx="corepack npx"
alias pac="sudo pacman -S"
alias pkglist="yay -Qe"
alias pn="corepack pnpm"
alias pnpm="corepack pnpm"
alias pnpx="corepack pnpx"
alias px="corepack pnpx"
alias refresh-mirror="sudo reflector --latest 5 --protocol https --country 'Singapore' --sort rate --save /etc/pacman.d/mirrorlist"
alias rm="trash-put"
alias rmr="rm"
alias s="yay -s"
alias search="yay -s"
alias sug="gh copilot suggest"
alias t="tmux"
alias tree="exa --tree --group-directories-first --icons --ignore-glob='*node_modules*'"
alias update-time="sudo ntpd -qg"
alias update="yay -Syyu"
alias vim="nvim"
alias vis="sudo nvim"
alias x="exit"
alias yarn="corepack yarn"
alias yarnpkg="corepack yarnpkg"

# Keybinding (defaults should work, but if you need custom key bindings, add them here)
bindkey -v

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"

source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
eval "$(fnm env --use-on-cd --shell zsh)"

# bun completions
[ -s "/home/karyana/.bun/_bun" ] && source "/home/karyana/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
