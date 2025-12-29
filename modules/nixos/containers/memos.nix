{ config, lib, ... }:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.containers.memos;
in
{
  options.plusultra.containers.memos = with types; {
    enable = mkBoolOpt false "Whether or not to enable memos service.";
    homepage = {
      name = mkOption {
        type = str;
        default = "Memos";
        description = "Service name for homepage";
      };
      description = mkOption {
        type = str;
        default = "Privacy-first note-taking app";
        description = "Service description for homepage";
      };
      icon = mkOption {
        type = str;
        default = "memos.png";
        description = "Icon for homepage";
      };
      category = mkOption {
        type = str;
        default = "Other";
        description = "Category for homepage";
      };
      port = mkOption {
        type = int;
        default = 5230;
        description = "Port for homepage link";
      };
      url = mkOption {
        type = nullOr str;
        default = null;
        description = "Custom URL for homepage link (overrides auto-generated URL)";
      };
      widget = {
        enable = mkOption {
          type = bool;
          default = false;
          description = "Enable API widget for homepage";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.memos = {
      image = "docker.io/neosmemo/memos:stable";
      autoStart = true;
      ports = [ "5230:5230" ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
      volumes = [
        "/mnt/appdata/memos:/var/opt/memos"
      ];
    };
  };
}
