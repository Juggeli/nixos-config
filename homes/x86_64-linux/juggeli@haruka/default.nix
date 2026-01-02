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
      nh = enabled;
      neovim = enabled;
      btop = enabled;
      rclone = enabled;
      lazygit = enabled;
      ffmpeg = enabled;
      ab-av1 = enabled;
      yazi = enabled;
      ai-agents = enabled;
      opencode = enabled;
      claude-code = enabled;
      bat = enabled;
      tmux = enabled;
      yuki-memory = enabled;
    };

    tools = {
      git = enabled;
      direnv = enabled;
      devtools = enabled;
      hdd-scraper = enabled;
    };
  };

  home.sessionPath = [ ];
}
