{ config, lib, ... }:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.containers.prowlarr;
in
{
  options.plusultra.containers.prowlarr = with types; {
    enable = mkBoolOpt false "Whether or not to prowlarr service.";
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
