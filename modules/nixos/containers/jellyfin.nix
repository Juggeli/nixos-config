{ config, lib, ... }:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.containers.jellyfin;
in
{
  options.plusultra.containers.jellyfin = with types; {
    enable = mkBoolOpt false "Whether or not to jellyfin service.";
    homepage = {
      name = mkOption {
        type = str;
        default = "Jellyfin";
        description = "Service name for homepage";
      };
      description = mkOption {
        type = str;
        default = "Media server";
        description = "Service description for homepage";
      };
      icon = mkOption {
        type = str;
        default = "jellyfin.png";
        description = "Icon for homepage";
      };
      category = mkOption {
        type = str;
        default = "Media";
        description = "Category for homepage";
      };
      port = mkOption {
        type = int;
        default = 8096;
        description = "Port for homepage link";
      };
    };
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
  };
}
