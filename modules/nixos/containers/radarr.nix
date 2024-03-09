{ config, lib, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.containers.radarr;
in
{
  options.plusultra.containers.radarr = with types; {
    enable = mkBoolOpt false "Whether or not to enable radarr service.";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.radarr = {
      image = "ghcr.io/hotio/radarr";
      autoStart = true;
      ports = [ "7878:7878" ];
      volumes = [
        "/mnt/appdata/radarr/:/config"
        "/tank/downloads/:/mnt/pool/downloads/"
        "/tank/media/:/mnt/pool/media/"
      ];
      environment = {
        PUID = "1000";
        PGID = "100";
      };
    };

    virtualisation.oci-containers.containers.radarr-anime = {
      image = "ghcr.io/hotio/radarr";
      autoStart = true;
      ports = [ "7879:7878" ];
      volumes = [
        "/mnt/appdata/radarr-anime/:/config"
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
