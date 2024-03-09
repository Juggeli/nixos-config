{ config, lib, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.containers.plex;
in
{
  options.plusultra.containers.plex = with types; {
    enable = mkBoolOpt false "Whether or not to enable plex service.";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.plex = {
      image = "ghcr.io/hotio/plex";
      autoStart = true;
      ports = [ "32400:32400" ];
      extraOptions = [
        ''--device="/dev/dri/renderD128:/dev/dri/renderD128"''
      ];
      volumes = [
        "/mnt/appdata/plex/:/config"
        "/tank/media/:/mnt/pool/media"
        "/mnt/pool/transcode/:/transcode"
      ];
    };
  };
}
