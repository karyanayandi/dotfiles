set fish_greeting ''

starship init fish | source
export STARSHIP_CONFIG=~/.starship/config.toml

## Aliases
alias ls "exa --group-directories-first --icons"
alias lsl "exa --group-directories-first -lh --icons"
alias ll "exa -al -g --icons"
alias vis "sudo nvim"
alias font-refresh "fc-cache -fv"
alias clone "git clone --depth 1"
alias merge "xrdb ~/.Xresources"
alias search "yay -s"
alias pac "sudo pacman -S"
alias install "yay -S"
alias update "yay -Syyu"
alias remove "yay -Rns"
alias clean "yay -Yc"
alias autoclean "sudo pacman -R $(pacman -Qdtq)"
alias pkglist "yay -Qe"
alias update-lock "betterlockscreen -u ~/Pictures --fx dim,pixel,blur"
alias update-time "sudo ntpd -qg"
alias refresh-mirror "sudo reflector --latest 5 --protocol https --country 'Singapore' --sort rate --save /etc/pacman.d/mirrorlist"

alias v "nvim"
alias nv "nvim"
alias vim "nvim"

alias c "clear"
alias cl "clear"
alias cdc "cd ~/.config"
alias cdp "cd ~/Projects"
alias cdd "cd ~/Database"
alias cdo "cd ~/Downloads"
alias cddo "cd ~/DevOps" 

alias vf "nvim ~/.config/fish/config.fish"
alias sf "source ~/.config/fish/config.fish"
alias vvv "nvim ~/.config/nvim/init.lua"

alias vbs "nvim ~/.bashrc"
alias sbs "source ~/.bashrc"

alias vi3 "nvim ~/.config/i3/config"
alias vpo "nvim ~/.config/polybar/config"

alias g "git"
alias gi "git init"
alias ga "git add . "
alias gcm "git commit -am"
alias gbm "git branch -M main"
alias gpso "git push origin main"
alias gplo "git pull origin main"
alias gst "git status"
alias glg "git log"

alias yi "yarn install"
alias ys "yarn start"
alias yd "yarn dev"
alias ya "yarn add"
alias yad "yarn add -D"

alias pni "pnpm install"
alias pns "pnpm start"
alias pnd "pnpm dev"
alias pna "pnpm add"
alias pnad "pnpm add -D"


alias ni "npm install"
alias nrs "npm run start"
alias nrd "npm run dev"
alias nid "npm install --save-dev"
alias nig "npm install --location=global"

## Keybinding
set fish_key_bindings fish_default_key_bindings

#pnpm
set -gx PNPM_HOME "/home/karyana/.local/share/pnpm"
set -gx PATH "$PNPM_HOME" $PATH

#dvm
# set -gx DVM_HOM  "/home/karyana/.dvm"
# set -gx PATH "$DVM_HOME" $PATH
