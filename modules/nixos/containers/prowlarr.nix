{ config, lib, ... }:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.containers.prowlarr;
in
{
  options.plusultra.containers.prowlarr = with types; {
    enable = mkBoolOpt false "Whether or not to prowlarr service.";
    homepage = {
      name = mkOption {
        type = str;
        default = "Prowlarr";
        description = "Service name for homepage";
      };
      description = mkOption {
        type = str;
        default = "Indexer manager";
        description = "Service description for homepage";
      };
      icon = mkOption {
        type = str;
        default = "prowlarr.png";
        description = "Icon for homepage";
      };
      category = mkOption {
        type = str;
        default = "Media";
        description = "Category for homepage";
      };
      port = mkOption {
        type = int;
        default = 9696;
        description = "Port for homepage link";
      };
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.prowlarr = {
      image = "ghcr.io/hotio/prowlarr";
      autoStart = true;
      ports = [ "9696:9696" ];
      volumes = [
        "/mnt/appdata/prowlarr/:/config"
      ];
    };

  };
}
