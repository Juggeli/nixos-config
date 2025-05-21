{ config, lib, ... }:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.containers.changedetection;
in
{
  options.plusultra.containers.changedetection = with types; {
    enable = mkBoolOpt false "Whether or not to enable changedetection service.";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.changedetection = {
      image = "ghcr.io/dgtlmoon/changedetection.io";
      autoStart = true;
      ports = [ "5000:5000" ];
      volumes = [
        "/mnt/appdata/changedetection:/datastore"
      ];
    };
    
    # Add to homepage
    plusultra.services.homepage.services = mkIf config.plusultra.services.homepage.enable {
      Monitoring = [{
        "Change Detection" = {
          href = "http://${config.networking.hostName}:5000";
          icon = "changedetection.png";
        };
      }];
    };
  };
}
