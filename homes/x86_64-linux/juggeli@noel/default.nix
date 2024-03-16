{ lib, config, ... }:
with lib.plusultra; {
  plusultra = {
    user = {
      enable = true;
      name = config.snowfallorg.user.name;
      impermanence = enabled;
    };

    apps = {
      wezterm = disabled;
      kitty = enabled;
      vscode = disabled;
      armcord = enabled;
      discord = {
        enable = false;
        chromium = enabled;
      };
      firefox = enabled;
      chrome = enabled;
      mpv = enabled;
      via = enabled;
      pdf = enabled;
      crypto = enabled;
      hydrus = enabled;
      floorp = enabled;
    };

    cli-apps = {
      fish = enabled;
      neovim = enabled;
      ffmpeg = enabled;
      imv = enabled;
      sshfs = enabled;
      vifm = enabled;
      speedtestpp = enabled;
      btop = enabled;
      tmux = enabled;
      yazi = enabled;
      lazygit = enabled;
      ab-av1 = enabled;
    };

    tools = {
      git = enabled;
      direnv = enabled;
    };
  };

  home.sessionPath = [
  ];
}
