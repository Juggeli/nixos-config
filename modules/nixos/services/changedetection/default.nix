{ config, lib, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.services.changedetection;
in
{
  options.plusultra.services.changedetection = with types; {
    enable = mkBoolOpt false "Whether or not to enable changedetection service.";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.changedetection = {
      image = "ghcr.io/dgtlmoon/changedetection.io";
      autoStart = true;
      ports = [ "5000:5000" ];
      volumes = [
        "/mnt/appdata/changedetection:/datastore"
      ];
    };
  };
}
