{ config, lib, ... }:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.containers.uptime-kuma;
in
{
  options.plusultra.containers.uptime-kuma = with types; {
    enable = mkBoolOpt false "Whether or not to enable uptime-kuma service.";
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
    
    # Add to homepage
    plusultra._module.args.plusultra.homepage.services = mkIf config.plusultra.services.homepage.enable {
      Monitoring = [{
        "Uptime Kuma" = {
          href = "http://${config.networking.hostName}:3001";
          icon = "uptime-kuma.png";
        };
      }];
    };
  };
}
