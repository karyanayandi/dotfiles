{pkgs, ...}: {
  bun = pkgs.mkShell {
    description = "Bun";
    buildInputs = with pkgs; [
      bun
      eslint_d
      prettierd
      stylelint
    ];
  };

  deno = pkgs.mkShell {
    description = "Deno";
    buildInputs = with pkgs; [
      deno
      stylelint
    ];
  };

  node = pkgs.mkShell {
    description = "Node.js";
    buildInputs = with pkgs; [
      nodejs
      corepack
      eslint_d
      prettierd
      stylelint
    ];
  };

  node18 = pkgs.mkShell {
    description = "Node.js 18";
    buildInputs = with pkgs; [
      nodejs_18
      corepack
      eslint_d
      prettierd
      stylelint
    ];
  };
}
