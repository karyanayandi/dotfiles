set fish_greeting ''

starship init fish | source
export STARSHIP_CONFIG=/home/karyana/.config/starship.toml

## Aliases
alias ls "exa --group-directories-first --icons"
alias lsl "exa --group-directories-first -lh --icons"
alias ll "exa -al -g --icons"
alias tree "exa --tree --level=2 --group-directories-first --icons --ignore-glob='*node_modules*'"
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
alias update-lock "betterlockscreen -u ~/.wallpaper.png --fx dim,pixel,blur"
alias update-time "sudo ntpd -qg"
alias refresh-mirror "sudo reflector --latest 5 --protocol https --country 'Singapore' --sort rate --save /etc/pacman.d/mirrorlist"

alias sshk "kitty +kitten ssh"

alias x exit
alias e nvim
alias nv nvim
alias vim nvim

alias c clear
alias cl clear
alias cdc "cd ~/.config"
alias cdp "cd ~/Projects"
alias cdd "cd ~/Database"
alias cdo "cd ~/Downloads"
alias cddo "cd ~/DevOps"
alias rm trash-put
alias rmr rm

alias vf "nvim ~/.config/fish/config.fish"
alias sf "source ~/.config/fish/config.fish"
alias vvv "nvim ~/.config/nvim/init.lua"

alias vbs "nvim ~/.bashrc"
alias sbs "source ~/.bashrc"

alias vi3 "nvim ~/.config/i3/config"
alias vpo "nvim ~/.config/polybar/config"

alias g git
alias gi "git init"
alias ga "git add . "
alias gcm "git commit -m"
alias gbm "git branch -M main"
alias gpso "git push origin main"
alias gplo "git pull origin main"
alias gst "git status"
alias glg "git log"
alias gpr "gh pr create"

alias yarn "corepack yarn"
alias yarnpkg "corepack yarnpkg"
alias pnpm "corepack pnpm"
alias pnpx "corepack pnpx"
alias npm "corepack npm"
alias npx "corepack npx"

alias yi "corepack yarn install"
alias ys "corepack yarn start"
alias yd "corepack yarn dev"
alias ya "corepack yarn add"
alias yad "corepack yarn add -D"

alias pn "corepack pnpm"
alias pni "corepack pnpm install"
alias pns "corepack pnpm start"
alias pnd "corepack pnpm dev"
alias pna "corepack pnpm add"
alias pnad "corepack pnpm add -D"
alias pnr "corepack pnpm remove"
alias pnu "corepack pnpm up --latest"

alias ni "corepack npm install"
alias nrs "corepack npm run start"
alias nrd "corepack npm run dev"
alias nid "corepack npm install --save-dev"
alias nig "corepack npm install --location=global"

alias lzg lazygit

## Keybinding
set fish_key_bindings fish_default_key_bindings

#pnpm
set -gx PNPM_HOME "/home/karyana/.local/share/pnpm"
set -gx PATH "$PNPM_HOME" $PATH
