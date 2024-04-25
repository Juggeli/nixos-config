{ config, lib, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.containers.stash;
in
{
  options.plusultra.containers.stash = with types; {
    enable = mkBoolOpt false "Whether or not to enable stash.";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.stash = {
      image = "ghcr.io/hotio/stash";
      autoStart = false;
      ports = [ "9999:9999" ];
      environment = {
        PUID = "1000";
        PGID = "100";
      };
      volumes = [
        "/mnt/appdata/stash/:/config"
        "/tank/sorted/:/data"
      ];
    };
  };
}
