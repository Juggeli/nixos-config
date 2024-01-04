{ config, pkgs, lib, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.hardware.liquidctl;
in
{
  options.plusultra.hardware.liquidctl = with types; {
    enable = mkBoolOpt false "Whether or not to enable liquidctl support";
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
      '';
      wantedBy = [ "multi-user.target" ];
    };
  };
}
