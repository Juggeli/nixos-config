{ lib, pkgs, config, osConfig ? { }, format ? "unknown", ... }:

with lib.plusultra;
{
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
      git = enabled;
      direnv = enabled;
    };
  };

  home.sessionPath = [
    "$HOME/src/flutter/bin"
    "$HOME/.pub-cache/bin"
  ];

  home.stateVersion = "23.05";
}
