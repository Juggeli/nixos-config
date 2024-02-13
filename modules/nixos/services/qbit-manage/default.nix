{ config, lib, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.services.qbit-manage;
in
{
  options.plusultra.services.qbit-manage = with types; {
    enable = mkBoolOpt false "Whether or not to enable qbit-manage service.";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.qbit-manage = {
      image = "ghcr.io/hotio/qbitmanage";
      autoStart = true;
      volumes = [
        "/mnt/appdata/qbit_manage/:/config/"
        "/mnt/pool/downloads/random/:/mnt/pool/downloads/random/"
      ];
      environment = {
        QBT_SCHEDULE = "30";
      };
    };
  };
}
