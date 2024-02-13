{ lib, config, ... }:
with lib.plusultra; {
  plusultra = {
    user = {
      enable = true;
      name = config.snowfallorg.user.name;
    };

    apps = {
      wezterm = {
        enable = false;
        fontSize = "15";
      };
      kitty = {
        enable = true;
        fontSize = 15;
      };
    };

    cli-apps = {
      fish = enabled;
      neovim = enabled;
      home-manager = enabled;
      btop = enabled;
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

  home.sessionPath = [
    "$HOME/src/flutter/bin"
    "$HOME/.pub-cache/bin"
    "$HOME/.local/bin"
  ];

  home.stateVersion = "23.05";
}
