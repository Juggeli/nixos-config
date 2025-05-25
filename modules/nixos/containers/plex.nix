{ config, lib, ... }:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.containers.plex;
in
{
  options.plusultra.containers.plex = with types; {
    enable = mkBoolOpt false "Whether or not to enable plex service.";
    homepage = {
      name = mkOption {
        type = str;
        default = "Plex";
        description = "Service name for homepage";
      };
      description = mkOption {
        type = str;
        default = "Media server";
        description = "Service description for homepage";
      };
      icon = mkOption {
        type = str;
        default = "plex.png";
        description = "Icon for homepage";
      };
      category = mkOption {
        type = str;
        default = "Media";
        description = "Category for homepage";
      };
      port = mkOption {
        type = int;
        default = 32400;
        description = "Port for homepage link";
      };
    };
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
  };
}
