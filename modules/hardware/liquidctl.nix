{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let
  cfg = config.modules.hardware.liquidctl;
in
{
  options.modules.hardware.liquidctl = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      liquidctl
    ];
    systemd.services.liquidctl = {
      description = "set pump speed and color";
      script = ''
        ${pkgs.liquidctl}/bin/liquidctl initialize all
        ${pkgs.liquidctl}/bin/liquidctl --match kraken set pump speed 70
        ${pkgs.liquidctl}/bin/liquidctl --match kraken set ring color spectrum-wave
        ${pkgs.liquidctl}/bin/liquidctl --match asus set sync color rainbow
      '';
      wantedBy = [ "multi-user.target" ];
    };
  };
}
