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

  home.sessionPath = [
  ];

  home.stateVersion = "23.11";
}
