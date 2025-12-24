{ config, lib, ... }:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.containers.watchstate;
in
{
  options.plusultra.containers.watchstate = with types; {
    enable = mkBoolOpt false "Whether or not to enable watchstate service.";
    homepage = {
      name = mkOption {
        type = str;
        default = "WatchState";
        description = "Service name for homepage";
      };
      description = mkOption {
        type = str;
        default = "Sync watch history";
        description = "Service description for homepage";
      };
      icon = mkOption {
        type = str;
        default = "watchstate.png";
        description = "Icon for homepage";
      };
      category = mkOption {
        type = str;
        default = "Media";
        description = "Category for homepage";
      };
      port = mkOption {
        type = int;
        default = 8484;
        description = "Port for homepage link";
      };
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.watchstate = {
      image = "ghcr.io/arabcoders/watchstate:latest";
      autoStart = false;
      ports = [ "8484:8080" ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
      volumes = [
        "/mnt/appdata/watchstate:/config"
      ];
    };
  };
}
