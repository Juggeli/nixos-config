{ lib, config, ... }:
with lib.plusultra; {
  plusultra = {
    user = {
      enable = true;
      name = config.snowfallorg.user.name;
    };

    apps = {
      wezterm = disabled;
      kitty = enabled;
      vscode = enabled;
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
      obsidian = enabled;
      crypto = enabled;
      hydrus = enabled;
    };

    cli-apps = {
      fish = enabled;
      neovim = enabled;
      home-manager = enabled;
      ffmpeg = enabled;
      imv = enabled;
      sshfs = enabled;
      vifm = enabled;
      speedtestpp = enabled;
      btop = enabled;
      tmux = enabled;
    };

    tools = {
      git = enabled;
      direnv = enabled;
    };
  };

  home.sessionPath = [
  ];
}
