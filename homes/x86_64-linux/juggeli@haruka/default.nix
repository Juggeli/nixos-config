{ lib, config, ... }:
with lib.plusultra; {
  plusultra = {
    user = {
      enable = true;
      name = config.snowfallorg.user.name;
    };

    cli-apps = {
      fish = enabled;
      neovim = enabled;
      home-manager = enabled;
      btop = enabled;
      rclone = enabled;
    };

    tools = {
      git = enabled;
      direnv = enabled;
    };
  };

  programs.fish.shellAbbrs = {
    nixsw = "doas nixos-rebuild switch --flake .#";
    nixup = "doas nixos-rebuild switch --flake .# --recreate-lock-file";
  };

  home.sessionPath = [
  ];
}
