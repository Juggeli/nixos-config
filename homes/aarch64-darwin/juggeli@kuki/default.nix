{
  lib,
  config,
  ...
}:
with lib.plusultra; {
  plusultra = {
    user = {
      enable = true;
      name = config.snowfallorg.user.name;
    };

    apps = {
      wezterm = {
        enable = true;
        fontSize = "15";
      };
    };

    cli-apps = {
      fish = enabled;
      neovim = enabled;
      home-manager = enabled;
    };

    tools = {
      git = {
        enable = true;
        userName = "juggeli";
        userEmail = "juggeli@gmail.com";
      };
      direnv = enabled;
    };
  };

  programs.fish.shellAbbrs = {
    nixsw = "darwin-rebuild switch --flake .#";
    nixup = "darwin-rebuild switch --flake .# --recreate-lock-file";
  };

  home.sessionPath = [
  ];

  home.stateVersion = "23.11";
}
