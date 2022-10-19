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
    ];

    # pkgs.writeTextFile {
    #   
    # }
    #
    # "/usr/local/share/model/vmaf_v0.6.1.json".text = ./vmaf_v0.6.1.json;
    # "/usr/local/share/model/vmaf_4k_v0.6.1.json".text = ./vmaf_4k_v0.6.1.json;
  };
}

