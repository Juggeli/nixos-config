{ config, lib, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.services.jackett;
in
{
  options.plusultra.services.jackett = with types; {
    enable = mkBoolOpt false "Whether or not to jackett service.";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.jackett = {
      image = "ghcr.io/hotio/jackett";
      autoStart = true;
      ports = [ "9117:9117" ];
      volumes = [
        "/mnt/appdata/jackett/:/config"
      ];
    };
  };
}
