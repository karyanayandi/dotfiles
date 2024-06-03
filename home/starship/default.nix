{
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$character";
      right_format = "$all";
      command_timeout = 1000;
      git_branch = {
        format = "[$symbol$branch(:$remote_branch)]($style)";
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
}
