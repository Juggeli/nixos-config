{ config, lib, ... }:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.containers.changedetection;
in
{
  options.plusultra.containers.changedetection = with types; {
    enable = mkBoolOpt false "Whether or not to enable changedetection service.";
    homepage = {
      name = mkOption {
        type = str;
        default = "Change Detection";
        description = "Service name for homepage";
      };
      description = mkOption {
        type = str;
        default = "Website change monitoring";
        description = "Service description for homepage";
      };
      icon = mkOption {
        type = str;
        default = "changedetection.png";
        description = "Icon for homepage";
      };
      category = mkOption {
        type = str;
        default = "Monitoring";
        description = "Category for homepage";
      };
      port = mkOption {
        type = int;
        default = 5000;
        description = "Port for homepage link";
      };
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.changedetection = {
      image = "ghcr.io/dgtlmoon/changedetection.io";
      autoStart = true;
      ports = [ "5000:5000" ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
      volumes = [
        "/mnt/appdata/changedetection:/datastore"
      ];
    };
  };
}
