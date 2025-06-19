{ config, lib, ... }:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.containers.sonarr-anime;
in
{
  options.plusultra.containers.sonarr-anime = with types; {
    enable = mkBoolOpt false "Whether or not to enable sonarr-anime service.";
    homepage = {
      name = mkOption {
        type = str;
        default = "Sonarr Anime";
        description = "Service name for homepage";
      };
      description = mkOption {
        type = str;
        default = "Anime TV show management";
        description = "Service description for homepage";
      };
      icon = mkOption {
        type = str;
        default = "sonarr.png";
        description = "Icon for homepage";
      };
      category = mkOption {
        type = str;
        default = "Media";
        description = "Category for homepage";
      };
      port = mkOption {
        type = int;
        default = 8999;
        description = "Port for homepage link";
      };
      url = mkOption {
        type = nullOr str;
        default = null;
        description = "Custom URL for homepage link (overrides auto-generated URL)";
      };
      widget = {
        enable = mkOption {
          type = bool;
          default = false;
          description = "Enable API widget for homepage";
        };
        type = mkOption {
          type = str;
          default = "sonarr";
          description = "Widget type for homepage";
        };
        fields = mkOption {
          type = listOf str;
          default = [
            "wanted"
            "queued"
            "series"
          ];
          description = "Widget fields to display";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.sonarr-anime = {
      image = "ghcr.io/hotio/sonarr";
      autoStart = false;
      ports = [ "8999:8989" ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
      environment = {
        PUID = "1000";
        PGID = "983";
      };
      volumes = [
        "/mnt/appdata/sonarr-anime/:/config/"
        "/tank/media/:/mnt/pool/media/"
      ];
    };
  };
}

