{ config, lib, ... }:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.containers.bazarr;
in
{
  options.plusultra.containers.bazarr = with types; {
    enable = mkBoolOpt false "Whether or not to enable bazarr.";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.bazarr = {
      image = "ghcr.io/hotio/bazarr";
      autoStart = false;
      ports = [ "6767:6767" ];
      environment = {
        PUID = "1000";
        PGID = "100";
        WEBUI_PORTS = "6767/tcp,6767/udp";
      };
      volumes = [
        "/mnt/appdata/bazarr/:/config"
        "/tank/media/:/mnt/pool/media/"
      ];
    };
  };
}
