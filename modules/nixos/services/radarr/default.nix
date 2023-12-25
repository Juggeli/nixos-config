{ config, lib, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.services.radarr;
in
{
  options.plusultra.services.radarr = with types; {
    enable = mkBoolOpt false "Whether or not to enable radarr service.";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.radarr = {
      image = "cr.hotio.dev/hotio/radarr";
      autoStart = true;
      ports = [ "7878:7878" ];
      volumes = [
        "/mnt/appdata/radarr/:/config"
        "/mnt/pool/downloads/:/mnt/pool/downloads/"
        "/mnt/pool/media/:/mnt/pool/media/"
      ];
      environment = {
        PUID = "1000";
        PGID = "100";
      };
    };
  };
}
