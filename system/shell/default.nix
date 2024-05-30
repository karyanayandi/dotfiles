{pkgs, ...}: let
  aliases = {
    sug = "gh copilot suggest";
    exp = "gh copilot explain";
    autoclean = "nix store gc";
    c = "clear";
    cat = "bat";
    cdc = "cd ~/.config/dotfiles";
    cdp = "cd ~/Projects";
    clean = "nix profile wipe-history && sudo nix-collect-garbage -d && sudo nix-collect-garbage --delete-old && sudo nix store gc && sudo nix-store --verify --repair --check-contents";
    delete-generations = "sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations";
    dev = "nix develop";
    e = "nvim";
    font-refresh = "fc-cache -fv";
    g = "git";
    list-generations = "sudo nix-env --profile /nix/var/nix/profiles/system --list-generations --profile /nix/var/nix/profiles/system";
    install = "nix-env -iA";
    ls = "eza --group-directories-first --icons";
    lsl = "eza --group-directories-first -lh --icons";
    ll = "eza -al -g --icons";
    lzg = "lazygit";
    pn = "corepack pnpm";
    rebuild = "sudo nixos-rebuild switch --flake .#computer";
    rm = "trash-put";
    rmr = "rm";
    rollback = "nix-env --rollback";
    search = "nix search nixpkgs";
    shell = "nix-shell";
    sshk = "kitty +kitten ssh";
    tree = "eza --tree --level=2 --group-directories-first --icons --ignore-glob='*node_modules*'";
    update = "nix-update";
    x = "exit";
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
