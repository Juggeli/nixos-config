{ config, lib, ... }:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.containers.radarr;
in
{
  options.plusultra.containers.radarr = with types; {
    enable = mkBoolOpt false "Whether or not to enable radarr service.";
    homepage = {
      name = mkOption {
        type = str;
        default = "Radarr";
        description = "Service name for homepage";
      };
      description = mkOption {
        type = str;
        default = "Movie management";
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
        default = 7878;
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
            "missing"
            "queued"
            "movies"
          ];
          description = "Widget fields to display";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.radarr = {
      image = "ghcr.io/hotio/radarr";
      autoStart = false;
      ports = [ "7878:7878" ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
      volumes = [
        "/mnt/appdata/radarr/:/config"
        "/tank/media/:/mnt/pool/media/"
      ];
      environment = {
        PUID = "1000";
        PGID = "100";
      };
    };
  };
}
