{ lib, config, ... }:
with lib.plusultra;
{
  plusultra = {
    user = {
      enable = true;
      name = config.snowfallorg.user.name;
    };

    cli-apps = {
      fish = enabled;
      neovim = enabled;
      btop = enabled;
      rclone = enabled;
      lazygit = enabled;
      ffmpeg = enabled;
      ab-av1 = enabled;
      yazi = enabled;
    };

    tools = {
      git = enabled;
      direnv = enabled;
    };
  };

  home.sessionPath = [ ];
}
