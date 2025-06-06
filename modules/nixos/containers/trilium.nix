{ config, lib, ... }:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.containers.trilium;
in
{
  options.plusultra.containers.trilium = with types; {
    enable = mkBoolOpt false "Whether or not to enable trilium service.";
    homepage = {
      name = mkOption {
        type = str;
        default = "Trilium";
        description = "Service name for homepage";
      };
      description = mkOption {
        type = str;
        default = "Note-taking application";
        description = "Service description for homepage";
      };
      icon = mkOption {
        type = str;
        default = "trilium.png";
        description = "Icon for homepage";
      };
      category = mkOption {
        type = str;
        default = "Apps";
        description = "Category for homepage";
      };
      port = mkOption {
        type = int;
        default = 8080;
        description = "Port for homepage link";
      };
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.trilium = {
      image = "ghcr.io/zadam/trilium";
      autoStart = true;
      ports = [ "8080:8080" ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
      volumes = [
        "/mnt/appdata/trilium/:/home/node/trilium-data"
      ];
    };

  };
}
