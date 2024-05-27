{pkgs, ...}: let
  aliases = {
    autoclean = "nix store gc";
    c = "clear";
    cdc = "cd ~/.config/dotfiles";
    cdp = "cd ~/Projects";
    clean = "sudo nix-collect-garbage -d";
    delete-generations = "sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations";
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
    search = "nix search nixpkgs";
    sshk = "kitty +kitten ssh";
    tree = "eza --tree --level=2 --group-directories-first --icons --ignore-glob='*node_modules*'";
    update = "nix-update";
    update-time = "sudo ntpd -qg";
    x = "exit";
    z = "zoxide";
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
