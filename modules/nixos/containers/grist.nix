{ config, lib, ... }:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.containers.grist;
in
{
  options.plusultra.containers.grist = with types; {
    enable = mkBoolOpt false "Whether or not to enable grist service.";
    homepage = {
      name = mkOption {
        type = str;
        default = "Grist";
        description = "Service name for homepage";
      };
      description = mkOption {
        type = str;
        default = "Spreadsheet database";
        description = "Service description for homepage";
      };
      icon = mkOption {
        type = str;
        default = "grist.png";
        description = "Icon for homepage";
      };
      category = mkOption {
        type = str;
        default = "Apps";
        description = "Category for homepage";
      };
      port = mkOption {
        type = int;
        default = 8484;
        description = "Port for homepage link";
      };
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.grist = {
      image = "docker.io/gristlabs/grist";
      autoStart = true;
      ports = [ "8484:8484" ];
      volumes = [
        "/mnt/appdata/grist/:/persist"
      ];
    };
  };
}
