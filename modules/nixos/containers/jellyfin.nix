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
        enableBlocks = mkOption {
          type = bool;
          default = true;
          description = "Enable blocks for widget";
        };
        fields = mkOption {
          type = listOf str;
          default = [
            "movies"
            "series"
            "episodes"
            "songs"
          ];
          description = "Widget fields to display";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.jellyfin = {
      image = "ghcr.io/hotio/jellyfin";
      autoStart = false;
      ports = [ "8096:8096" ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
      extraOptions = [
        ''--group-add="303"''
        "--device=/dev/dri/renderD128"
      ];
      volumes = [
        "/mnt/appdata/jellyfin/:/config"
        "/tank/media/:/media"
        "/mnt/appdata/transcode/:/transcode"
      ];
    };
  };
}
