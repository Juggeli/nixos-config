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
      image = "ghcr.io/hotio/sonarr";
      autoStart = true;
      ports = [ "8989:8989" ];
      volumes = [
        "/mnt/appdata/sonarr/:/config"
        "/tank/downloads/:/mnt/pool/downloads/"
        "/tank/media/:/mnt/pool/media/"
      ];
      environment = {
        PUID = "1000";
        PGID = "100";
      };
    };

    virtualisation.oci-containers.containers.sonarr-anime = {
      image = "ghcr.io/hotio/sonarr";
      autoStart = true;
      ports = [ "8999:8989" ];
      volumes = [
        "/mnt/appdata/sonarr-anime/:/config"
        "/tank/downloads/:/mnt/pool/downloads/"
        "/tank/media/:/mnt/pool/media/"
      ];
      environment = {
        PUID = "1000";
        PGID = "100";
      };
    };
  };
}
