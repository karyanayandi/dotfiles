{pkgs, ...}: let
  aliases = {
    autoclean = "nix store gc";
    bn = "bun";
    br = "bun run";
    bx = "bunx";
    c = "clear";
    cat = "bat";
    cdc = "cd ~/.config/dotfiles";
    cdp = "cd ~/Codes";
    clean-build = "nix profile wipe-history && nix-collect-garbage -d && nix-collect-garbage --delete-old && nix store gc && sudo nix-collect-garbage -d && sudo nix-collect-garbage --delete-old && sudo nix store gc";
    clean-code = "find . -type d -name 'node_modules' -o -name '.next' -o -name '.turbo' -exec rm -rf {} + -o -type f -name '*.astro' -exec rm -f {} +;";
    clean-trash = "rm -rf ~/.local/share/Trash/*";
    dbox = "distrobox";
    delete-generations = "sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations";
    dev = "nix develop";
    e = "nvim";
    exp = "gh copilot explain";
    font-list = "fc-list : family";
    font-refresh = "fc-cache -fv";
    ft = "nvim $(fzf -m --preview 'bat --color=always --style=header,grid --line-range :500 {}')";
    g = "git";
    install = "nix-env -iA";
    list-generations = "sudo nix-env --profile /nix/var/nix/profiles/system --list-generations --profile /nix/var/nix/profiles/system";
    ll = "eza -al -g --icons";
    ls = "eza --group-directories-first --icons";
    lsl = "eza --group-directories-first -lh --icons";
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
