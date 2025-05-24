{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.apps.mpv;
in
{
  options.plusultra.apps.mpv = with types; {
    enable = mkBoolOpt false "Whether or not to enable mpv.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      (mpv.override { scripts = [ ]; })
    ];

    xdg.configFile = {
      "mpv/mpv.conf".text = ''
        volume=40
        osd-on-seek=msg
        autofit=1920x1080
        deband=no
      '';
      "mpv/input.conf".text = ''
        WHEEL_DOWN seek -10
        WHEEL_UP seek 10
        WHEEL_RIGHT add volume 2
        WHEEL_LEFT add volume -2
      '';
      "mpv/scripts/delete_file.lua".source = ./delete_file.lua;
      "mpv/scripts/brightness_control.lua".source = ./brightness_control.lua;
    };
  };
}
