{pkgs, ...}: let
  aliases = {
    autoclean = "nix store gc";
    bn = "bun";
    bx = "bunx";
    c = "clear";
    cat = "bat";
    cdc = "cd ~/.config/dotfiles";
    cdp = "cd ~/Codes";
    clean = "nix profile wipe-history && sudo nix-collect-garbage -d && sudo nix-collect-garbage --delete-old && sudo nix store gc && sudo nix-store --verify --repair --check-contents";
    clean-node = "find . -type d -name 'node_modules' -exec rm -rf {} +;";
    clean-trash = "rm -rf ~/.local/share/Trash/*";
    delete-generations = "sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations";
    dev = "nix develop";
    dbox = "distrobox";
    e = "nvim";
    exp = "gh copilot explain";
    font-refresh = "fc-cache -fv";
    ft = "nvim $(fzf -m --preview 'bat --color=always --style=header,grid --line-range :500 {}')";
    g = "git";
    list-generations = "sudo nix-env --profile /nix/var/nix/profiles/system --list-generations --profile /nix/var/nix/profiles/system";
    install = "nix-env -iA";
    ls = "eza --group-directories-first --icons";
    lsl = "eza --group-directories-first -lh --icons";
    ll = "eza -al -g --icons";
    lzg = "lazygit";
    npm = "corepack npm";
    npx = "corepack npx";
    pn = "corepack pnpm";
    pnpm = "corepack pnpm";
    pnpx = "corepack pnpx";
    px = "corepack pnpx";
    rebuild = "sudo nixos-rebuild switch --flake .#computer";
    rollback = "nix-env --rollback";
    search = "nix search nixpkgs";
    shell = "nix-shell";
    sug = "gh copilot suggest";
    t = "tmux";
    tree = "eza --tree --group-directories-first --icons --ignore-glob='*node_modules*'";
    update = "nix-update";
    x = "exit";
    yarn = "corepack yarn";
    yarnpkg = "corepack yarnpkg";
  };
in {
  programs = {
    fish = {
      enable = true;
      shellAliases = aliases;
      interactiveShellInit = ''
        set -g fish_greeting ""
      '';
    };
    bash = {
      shellAliases = aliases;
    };
    starship = {
      enable = true;
    };
  };
  users.defaultUserShell = pkgs.fish;
}
