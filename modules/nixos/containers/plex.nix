{ config, lib, ... }:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.containers.plex;
in
{
  options.plusultra.containers.plex = with types; {
    enable = mkBoolOpt false "Whether or not to enable plex service.";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.plex = {
      image = "ghcr.io/hotio/plex";
      autoStart = false;
      ports = [ "32400:32400" ];
      extraOptions = [
        ''--group-add="303"''
        ''--device=/dev/dri/renderD128''
      ];
      volumes = [
        "/mnt/appdata/plex/:/config"
        "/tank/media/:/mnt/pool/media"
        "/mnt/appdata/plex-transcode/:/transcode"
      ];
    };
    
    # Add Plex to homepage services if homepage is enabled
    plusultra.services.homepage.services = mkIf config.plusultra.services.homepage.enable {
      Media = [{
        Plex = {
          href = "http://${config.networking.hostName}:32400";
          icon = "plex.png";
        };
      }];
    };
  };
}
