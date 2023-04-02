inputs@{ options, config, lib, pkgs, ... }:

with lib;
with lib.internal;
let
  cfg = config.plusultra.apps.mpv;
in
{
  options.plusultra.apps.mpv = with types; {
    enable = mkBoolOpt false "Whether or not to enable mpv.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      mpv
    ];

    plusultra.home = {
      configFile = {
        "mpv/mpv.conf".text = ''
          volume=60
          osd-on-seek=msg
          autofit=80%
          deband=no
        '';
      };
    };
  };
}
