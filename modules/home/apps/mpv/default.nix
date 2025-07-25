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
    brightnessControl = mkBoolOpt false "Whether or not to enable ddcutil brightness control on fullscreen.";
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
    }
    // lib.optionalAttrs cfg.brightnessControl {
      "mpv/scripts/brightness_control.lua".source = ./brightness_control.lua;
    };
  };
}
