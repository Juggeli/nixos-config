{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.media.mpv;
in
{
  options.modules.desktop.media.mpv = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      mpv
    ];

    hm.xdg.configFile."mpv/mpv.conf".text = ''
      volume=60
      osd-on-seek=msg
      autofit=1600x900
      profile=gpu-hq 
      deband=no 
      gpu-api=vulkan
      gpu-context=wayland
    '';
  };
}
