{...}: let
  aliases = {
    sug = "gh copilot suggest";
    exp = "gh copilot explain";
    autoclean = "nix store gc";
    c = "clear";
    cat = "bat";
    cdc = "cd ~/.config/dotfiles";
    cdp = "cd ~/Projects";
    clean = "nix profile wipe-history && sudo nix-collect-garbage -d && sudo nix-collect-garbage --delete-old && sudo nix store gc && sudo nix-store --verify --repair --check-contents";
    clean-node = "find . -type d -name 'node_modules' -exec rm -rf {} +;";
    clean-trash = "rm -rf ~/.local/share/Trash/*";
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
    rollback = "nix-env --rollback";
    search = "nix search nixpkgs";
    shell = "nix-shell";
    t = "tmux";
    tx = "tmuxifier";
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
      settings = {
        add_newline = false;
        command_timeout = 1000;
        git_branch = {
          symbol = " ";
          format = "[$symbol$branch]($style)";
        };
        aws = {
          format = "[$symbol(profile: \"$profile\" )(\(region: $region\) )]($style)";
          disabled = false;
          style = "bold blue";
          symbol = " ";
        };
        golang = {
          format = "[ ](bold cyan)";
        };
        docker_context = {
          disabled = true;
        };
      };
    };
  };
}