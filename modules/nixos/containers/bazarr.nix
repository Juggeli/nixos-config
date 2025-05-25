{ config, lib, ... }:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.containers.bazarr;
in
{
  options.plusultra.containers.bazarr = with types; {
    enable = mkBoolOpt false "Whether or not to enable bazarr.";
    homepage = {
      name = mkOption {
        type = str;
        default = "Bazarr";
        description = "Service name for homepage";
      };
      description = mkOption {
        type = str;
        default = "Subtitle management";
        description = "Service description for homepage";
      };
      icon = mkOption {
        type = str;
        default = "bazarr.png";
        description = "Icon for homepage";
      };
      category = mkOption {
        type = str;
        default = "Media";
        description = "Category for homepage";
      };
      port = mkOption {
        type = int;
        default = 6767;
        description = "Port for homepage link";
      };
      widget = {
        enable = mkOption {
          type = bool;
          default = false;
          description = "Enable API widget for homepage";
        };
        apiKey = mkOption {
          type = str;
          default = "";
          description = "API key for Bazarr (find in Settings > General)";
        };
        apiKeyFile = mkOption {
          type = nullOr path;
          default = null;
          description = "Path to file containing API key for Bazarr";
        };
        fields = mkOption {
          type = listOf str;
          default = ["missingEpisodes" "missingMovies"];
          description = "Widget fields to display";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.bazarr = {
      image = "ghcr.io/hotio/bazarr";
      autoStart = false;
      ports = [ "6767:6767" ];
      environment = {
        PUID = "1000";
        PGID = "100";
        WEBUI_PORTS = "6767/tcp,6767/udp";
      };
      volumes = [
        "/mnt/appdata/bazarr/:/config"
        "/tank/media/:/mnt/pool/media/"
      ];
    };

  };
}
