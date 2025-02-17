# Initialize Starship prompt
eval "$(starship init zsh)"
export STARSHIP_CONFIG="$HOME/.config/starship.toml"

# Aliases
alias autoclean="sudo pacman -R $(pacman -Qdtq)"
alias bn="bun"
alias bx="bunx"
alias c="clear"
alias cdc="cd ~/.config/dotfiles"
alias cdp="cd ~/Codes"
alias cl="clear"
alias clean="yay -Yc"
alias clean-code="find . -type d -name 'node_modules' -o -name '.next' -o -name '.turbo' -exec rm -rf {} + -o -type f -name '*.astro' -exec rm -f {} +;"
alias d="yay -Rns"
alias dbox="distrobox"
alias delete="yay -Rns"
alias docker="podman"
alias e="nvim"
alias eb "nvim ~/.bashrc"
alias en="nvim ~/.config/nvim/init.lua"
alias es="nvim ~/.config/sway/config"
alias exp="gh copilot explain"
alias ez="nvim ~/.zshrc"
alias font-list="fc-list : family"
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
alias u="yay -Syyu"
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

eval "$(fnm env --use-on-cd --shell zsh)"

# bun completions
[ -s "/home/karyana/.bun/_bun" ] && source "/home/karyana/.bun/_bun"

#fzf
export FZF_DEFAULT_COMMAND='find .'

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk

zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-history-substring-search
zinit light zsh-users/zsh-syntax-highlighting
zinit light hlissner/zsh-autopair
zinit light Aloxaf/fzf-tab
