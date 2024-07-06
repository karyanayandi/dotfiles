{config, ...}: let
  aliases = {
    autoclean = "nix store gc";
    c = "clear";
    cat = "bat";
    cdc = "cd ~/.config/dotfiles";
    cdp = "cd ~/Codes";
    clean = "nix profile wipe-history && sudo nix-collect-garbage -d && sudo nix-collect-garbage --delete-old && sudo nix store gc && sudo nix-store --verify --repair --check-contents";
    clean-node = "find . -type d -name 'node_modules' -exec rm -rf {} +;";
    clean-trash = "rm -rf ~/.local/share/Trash/*";
    delete-generations = "sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations";
    dev = "nix develop";
    e = "nvim";
    exp = "gh copilot explain";
    font-refresh = "fc-cache -fv";
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
    px = "corepack pnx";
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
  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = aliases;
    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
    };
    oh-my-zsh = {
      enable = true;
      plugins = ["z"];
    };
  };
}
