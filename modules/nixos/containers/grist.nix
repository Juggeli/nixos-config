{ config, lib, ... }:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.containers.grist;
in
{
  options.plusultra.containers.grist = with types; {
    enable = mkBoolOpt false "Whether or not to enable grist service.";
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
    
    # Add to homepage
    plusultra._module.args.plusultra.homepage.services = mkIf config.plusultra.services.homepage.enable {
      Apps = [{
        Grist = {
          href = "http://${config.networking.hostName}:8484";
          icon = "grist.png";
        };
      }];
    };
  };
}
