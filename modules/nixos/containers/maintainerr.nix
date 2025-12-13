{ config, lib, ... }:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.containers.maintainerr;
in
{
  options.plusultra.containers.maintainerr = with types; {
    enable = mkBoolOpt false "Whether or not to enable maintainerr.";
    homepage = {
      name = mkOption {
        type = str;
        default = "Maintainerr";
        description = "Service name for homepage";
      };
      description = mkOption {
        type = str;
        default = "Media maintenance automation";
        description = "Service description for homepage";
      };
      icon = mkOption {
        type = str;
        default = "maintainerr.png";
        description = "Icon for homepage";
      };
      category = mkOption {
        type = str;
        default = "Media";
        description = "Category for homepage";
      };
      port = mkOption {
        type = int;
        default = 6246;
        description = "Port for homepage link";
      };
      widget = {
        enable = mkOption {
          type = bool;
          default = false;
          description = "Enable API widget for homepage";
        };
        fields = mkOption {
          type = listOf str;
          default = [ ];
          description = "Widget fields to display";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.maintainerr = {
      image = "ghcr.io/maintainerr/maintainerr:latest";
      autoStart = false;
      ports = [ "6246:6246" ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
      environment = {
        TZ = "Europe/Helsinki";
      };
      volumes = [
        "/mnt/appdata/maintainerr:/opt/data"
      ];
      user = "1000:983";
    };
  };
}
