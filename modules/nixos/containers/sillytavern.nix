{ config, lib, ... }:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.containers.sillytavern;
in
{
  options.plusultra.containers.sillytavern = with types; {
    enable = mkBoolOpt false "Whether or not to enable SillyTavern service.";
    homepage = {
      name = mkOption {
        type = str;
        default = "SillyTavern";
        description = "Service name for homepage";
      };
      description = mkOption {
        type = str;
        default = "LLM frontend";
        description = "Service description for homepage";
      };
      icon = mkOption {
        type = str;
        default = "sillytavern.png";
        description = "Icon for homepage";
      };
      category = mkOption {
        type = str;
        default = "Apps";
        description = "Category for homepage";
      };
      port = mkOption {
        type = int;
        default = 8000;
        description = "Port for homepage link";
      };
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.sillytavern = {
      image = "ghcr.io/sillytavern/sillytavern:latest";
      autoStart = true;
      ports = [ "8000:8000" ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
      volumes = [
        "/mnt/appdata/sillytavern/config:/home/node/app/config"
        "/mnt/appdata/sillytavern/data:/home/node/app/data"
      ];
    };

  };
}
