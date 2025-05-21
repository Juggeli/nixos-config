{ config, lib, ... }:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.containers.sonarr;
in
{
  options.plusultra.containers.sonarr = with types; {
    enable = mkBoolOpt false "Whether or not to enable sonarr service.";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.sonarr = {
      image = "ghcr.io/hotio/sonarr";
      autoStart = false;
      ports = [ "8989:8989" ];
      volumes = [
        "/mnt/appdata/sonarr/:/config/"
        "/tank/media/:/mnt/pool/media/"
      ];
      environment = {
        PUID = "1000";
        PGID = "100";
      };
    };

    virtualisation.oci-containers.containers.sonarr-anime = {
      image = "ghcr.io/hotio/sonarr";
      autoStart = false;
      ports = [ "8999:8989" ];
      volumes = [
        "/mnt/appdata/sonarr-anime/:/config/"
        "/tank/media/:/mnt/pool/media/"
      ];
      environment = {
        PUID = "1000";
        PGID = "100";
      };
    };
    
    # Add to homepage
    plusultra.services.homepage.services = mkIf config.plusultra.services.homepage.enable {
      Media = [
        {
          Sonarr = {
            href = "http://${config.networking.hostName}:8989";
            icon = "sonarr.png";
          };
        }
        {
          "Sonarr Anime" = {
            href = "http://${config.networking.hostName}:8999";
            icon = "sonarr.png";
          };
        }
      ];
    };
  };
}
