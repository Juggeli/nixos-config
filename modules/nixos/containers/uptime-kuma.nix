{ config, lib, ... }:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.containers.uptime-kuma;
in
{
  options.plusultra.containers.uptime-kuma = with types; {
    enable = mkBoolOpt false "Whether or not to enable uptime-kuma service.";
    homepage = {
      name = mkOption {
        type = str;
        default = "Uptime Kuma";
        description = "Service name for homepage";
      };
      description = mkOption {
        type = str;
        default = "Status monitoring";
        description = "Service description for homepage";
      };
      icon = mkOption {
        type = str;
        default = "uptime-kuma.png";
        description = "Icon for homepage";
      };
      category = mkOption {
        type = str;
        default = "Monitoring";
        description = "Category for homepage";
      };
      port = mkOption {
        type = int;
        default = 3001;
        description = "Port for homepage link";
      };
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.uptime-kuma = {
      image = "louislam/uptime-kuma";
      autoStart = true;
      ports = [ "3001:3001" ];
      volumes = [
        "/mnt/appdata/uptime-kuma:/app/data"
      ];
      environment = {
        PUID = "1000";
        PGID = "100";
      };
      extraOptions = [
        "--cap-add=NET_RAW"
      ];
    };

  };
}
