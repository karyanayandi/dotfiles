# Initialize Starship prompt
eval "$(starship init zsh)"
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"

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
export LS_COLORS="$(vivid generate aurora)"
export DOCKER_HOST=unix:///run/user/1000/podman/podman.sock

# Aliases
alias autoclean="sudo pacman -R $(pacman -Qdtq)"
alias bn="bun"
alias br="bun run"
alias bx="bunx"
alias c="clear"
alias cat="bat"
alias cdc="cd ~/.config/dotfiles"
alias cdp="cd ~/Codes"
alias cl="clear"
alias clean-code="find . -type d -name 'node_modules' -o -name '.next' -o -name '.turbo' -exec rm -rf {} + -o -type f -name '*.astro' -exec rm -f {} +;"
alias clean="yay -Yc"
alias dbox="distrobox"
alias delete="yay -Rns"
alias docker="podman"
alias e="nvim"
alias eb="nvim ~/.bashrc"
alias ef="nvim ~/config/fish/config.fish"
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
alias lzd="lazydocker"
alias lzg="lazygit"
alias npm="corepack npm"
alias npx="corepack npx"
alias pac="sudo pacman -S"
alias pkglist="yay -Qe"
alias pn="corepack pnpm"
alias pnpm="corepack pnpm"
alias pnpx="corepack pnpx"
alias px="corepack pnpx"
alias r="yay -Rns"
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

# fzf
export FZF_DEFAULT_COMMAND="rg -uu \
          --files \
          -H"
export FZF_DEFAULT_OPTS="\
--color=bg+:#353b45,bg:#282c34,spinner:#eceff4,hl:#bf616a \
--color=fg:#c8ccd4,header:#bf616a,info:#8fbcbb,pointer:#eceff4 \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#8fbcbb,hl+:#bf616a \
--color=selected-bg:#3e4451 \
--multi"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

search_text() {
    ~/.local/bin/search-text.sh
}

# Bind Ctrl+T to run the function
bindkey -s '^T' 'search_text\n'

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
