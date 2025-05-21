{ config, lib, ... }:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.containers.jellyfin;
in
{
  options.plusultra.containers.jellyfin = with types; {
    enable = mkBoolOpt false "Whether or not to jellyfin service.";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.jellyfin = {
      image = "ghcr.io/hotio/jellyfin";
      autoStart = false;
      ports = [ "8096:8096" ];
      extraOptions = [
        ''--group-add="303"''
        ''--device=/dev/dri/renderD128''
      ];
      volumes = [
        "/mnt/appdata/jellyfin/:/config"
        "/tank/media/:/media"
        "/mnt/appdata/transcode/:/transcode"
      ];
    };
    
    # Add Jellyfin to homepage services if homepage is enabled
    plusultra._module.args.plusultra.homepage.services = mkIf config.plusultra.services.homepage.enable {
      Media = [
        {
          Jellyfin = {
            href = "http://${config.networking.hostName}:8096";
            icon = "jellyfin.png";
          };
        }
      ];
    };
  };
}
