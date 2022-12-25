{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.media.ffmpeg;
in
{
  options.modules.desktop.media.ffmpeg = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      ffmpeg_5-full
      svt-av1
      mkvtoolnix
    ];
  };
}

