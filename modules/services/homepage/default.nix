{ options, config, pkgs, lib, ... }:

with lib;
with lib.internal;
let cfg = config.plusultra.services.homepage;
in
{
  options.plusultra.services.homepage = with types; {
    enable = mkBoolOpt false "Whether or not to enable homepage service.";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.homepage = {
      image = "ghcr.io/benphelps/homepage:latest";
      autoStart = true;
      ports = [ "3000:3000" ];
      volumes = [
        "/mnt/appdata/homepage:/app/config"
        "/var/run/docker.sock:/var/run/docker.sock"
      ];
      environment = {
        PUID = "1000";
        PGID = "100";
      };
      extraOptions = [ "--network=docker-net" ];
    };
  };
}

