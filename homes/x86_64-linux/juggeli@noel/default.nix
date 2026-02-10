{
  lib,
  pkgs,
  ...
}:
with lib.plusultra;
{
  plusultra = {
    roles.home-common = enabled;
    user.impermanence = enabled;

    apps = {
      kitty.fontSize = lib.mkForce 14;
      discord = enabled;
      firefox = enabled;
      chrome = enabled;
      via = enabled;
      pdf = enabled;
      crypto = enabled;
      hydrus = enabled;
      obsidian = enabled;
      anytype = enabled;
      mpv.brightnessControl = true;
      vscode = enabled;
      comfyui = enabled;
    };

    cli-apps = {
      ffmpeg = enabled;
      imv = enabled;
      sshfs = enabled;
      tmux = enabled;
      ab-av1 = enabled;
      nushell = enabled;
    };

    desktop = {
      waybar = enabled;
    };

    tools = {
      sorter = enabled;
    };
  };

  home.packages = with pkgs; [
    plusultra.process-anime
  ];

  home.sessionPath = [
  ];

  home.pointerCursor = {
    x11.enable = true;
    gtk.enable = true;
    package = pkgs.plusultra.banana-cursor-dreams;
    size = 64;
    name = "Banana-Catppuccin-Mocha";
  };
}
