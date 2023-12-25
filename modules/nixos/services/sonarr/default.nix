{ config, lib, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.services.sonarr;
in
{
  options.plusultra.services.sonarr = with types; {
    enable = mkBoolOpt false "Whether or not to enable sonarr service.";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.sonarr = {
      image = "cr.hotio.dev/hotio/sonarr";
      autoStart = true;
      ports = [ "8989:8989" ];
      volumes = [
        "/mnt/appdata/sonarr/:/config"
        "/mnt/pool/downloads/:/mnt/pool/downloads/"
        "/mnt/pool/media/:/mnt/pool/media/"
      ];
      environment = {
        PUID = "1000";
        PGID = "100";
      };
    };
  };
}
