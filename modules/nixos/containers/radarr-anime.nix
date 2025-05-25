{ config, lib, ... }:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.containers.radarr-anime;
in
{
  options.plusultra.containers.radarr-anime = with types; {
    enable = mkBoolOpt false "Whether or not to enable radarr-anime service.";
    homepage = {
      name = mkOption {
        type = str;
        default = "Radarr Anime";
        description = "Service name for homepage";
      };
      description = mkOption {
        type = str;
        default = "Anime movie management";
        description = "Service description for homepage";
      };
      icon = mkOption {
        type = str;
        default = "radarr.png";
        description = "Icon for homepage";
      };
      category = mkOption {
        type = str;
        default = "Media";
        description = "Category for homepage";
      };
      port = mkOption {
        type = int;
        default = 7879;
        description = "Port for homepage link";
      };
    };
  };

  config = mkIf cfg.enable {
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
  };
}