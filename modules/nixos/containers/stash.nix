{ config, lib, ... }:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.containers.stash;
in
{
  options.plusultra.containers.stash = with types; {
    enable = mkBoolOpt false "Whether or not to enable stash.";
    homepage = {
      name = mkOption {
        type = str;
        default = "Stash";
        description = "Service name for homepage";
      };
      description = mkOption {
        type = str;
        default = "Media organizer";
        description = "Service description for homepage";
      };
      icon = mkOption {
        type = str;
        default = "stash.png";
        description = "Icon for homepage";
      };
      category = mkOption {
        type = str;
        default = "Media";
        description = "Category for homepage";
      };
      port = mkOption {
        type = int;
        default = 9999;
        description = "Port for homepage link";
      };
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.stash = {
      image = "ghcr.io/hotio/stash";
      autoStart = false;
      ports = [ "9999:9999" ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
      environment = {
        PUID = "1000";
        PGID = "100";
      };
      volumes = [
        "/mnt/appdata/stash/:/config"
        "/tank/sorted/:/data"
      ];
    };
  };
}
