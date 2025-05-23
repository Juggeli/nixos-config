{ config, lib, ... }:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.containers.trilium;
in
{
  options.plusultra.containers.trilium = with types; {
    enable = mkBoolOpt false "Whether or not to enable trilium service.";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.trilium = {
      image = "ghcr.io/zadam/trilium";
      autoStart = true;
      ports = [ "8080:8080" ];
      volumes = [
        "/mnt/appdata/trilium/:/home/node/trilium-data"
      ];
    };
    
    # Add to homepage
    plusultra._module.args.plusultra.homepage.services = mkIf config.plusultra.services.homepage.enable {
      Apps = [{
        Trilium = {
          href = "http://${config.networking.hostName}:8080";
          icon = "trilium.png";
        };
      }];
    };
  };
}
