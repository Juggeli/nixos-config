{ config, lib, ... }:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.containers.sonarr;
in
{
  options.plusultra.containers.sonarr = with types; {
    enable = mkBoolOpt false "Whether or not to enable sonarr service.";
    homepage = {
      name = mkOption {
        type = str;
        default = "Sonarr";
        description = "Service name for homepage";
      };
      description = mkOption {
        type = str;
        default = "TV show management";
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
        default = 8989;
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
  };
}
