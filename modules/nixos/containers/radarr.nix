{ config, lib, ... }:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.containers.radarr;
in
{
  options.plusultra.containers.radarr = with types; {
    enable = mkBoolOpt false "Whether or not to enable radarr service.";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.radarr = {
      image = "ghcr.io/hotio/radarr";
      autoStart = false;
      ports = [ "7878:7878" ];
      volumes = [
        "/mnt/appdata/radarr/:/config"
        "/tank/media/:/mnt/pool/media/"
      ];
      environment = {
        PUID = "1000";
        PGID = "100";
      };
    };

    virtualisation.oci-containers.containers.radarr-anime = {
      image = "ghcr.io/hotio/radarr";
      autoStart = false;
      ports = [ "7879:7878" ];
      volumes = [
        "/mnt/appdata/radarr-anime/:/config"
        "/tank/media/:/mnt/pool/media/"
      ];
      environment = {
        PUID = "1000";
        PGID = "100";
      };
    };
    
    # Add to homepage
    plusultra._module.args.plusultra.homepage.services = mkIf config.plusultra.services.homepage.enable {
      Media = [
        {
          Radarr = {
            href = "http://${config.networking.hostName}:7878";
            icon = "radarr.png";
          };
        }
        {
          "Radarr Anime" = {
            href = "http://${config.networking.hostName}:7879";
            icon = "radarr.png";
          };
        }
      ];
    };
  };
}
