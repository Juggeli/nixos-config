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
      vscode = enabled;
      discord = {
        enable = true;
        chromium = enabled;
      };
      firefox = enabled;
      chrome = enabled;
      kitty = enabled;
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
