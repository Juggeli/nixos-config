{
  lib,
  pkgs,
  config,
  osConfig ? {},
  format ? "unknown",
  ...
}:
with lib.plusultra; {
  plusultra = {
    user = {
      enable = true;
      name = config.snowfallorg.user.name;
    };

    apps = {
      wezterm = enabled;
    };

    cli-apps = {
      fish = enabled;
      neovim = enabled;
      home-manager = enabled;
    };

    tools = {
      git = {
        enable = true;
        userName = "jukka.alavesa";
        userEmail = "jukka.alavesa@codemate.com";
      };
      direnv = enabled;
    };
  };

  programs.fish.shellAbbrs = {
    nixsw = "darwin-rebuild switch --flake .#";
    nixup = "darwin-rebuild switch --flake .# --recreate-lock-file";
  };

  home.sessionPath = [
    "$HOME/src/flutter/bin"
    "$HOME/.pub-cache/bin"
  ];

  home.stateVersion = "23.05";
}
