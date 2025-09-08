{ config, lib, ... }:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.containers.lanraragi;
in
{
  options.plusultra.containers.lanraragi = with types; {
    enable = mkBoolOpt false "Whether or not to enable LANraragi.";
    homepage = {
      name = mkOption {
        type = str;
        default = "LANraragi";
        description = "Service name for homepage";
      };
      description = mkOption {
        type = str;
        default = "Archive reader";
        description = "Service description for homepage";
      };
      icon = mkOption {
        type = str;
        default = "lanraragi.png";
        description = "Icon for homepage";
      };
      category = mkOption {
        type = str;
        default = "Media";
        description = "Category for homepage";
      };
      port = mkOption {
        type = int;
        default = 3333;
        description = "Port for homepage link";
      };
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.lanraragi = {
      image = "docker.io/difegue/lanraragi";
      autoStart = true;
      ports = [ "3333:3000" ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
      volumes = [
        "/mnt/appdata/lanraragi:/home/koyomi/lanraragi/database"
        "/tank/documents/lanraragi:/home/koyomi/lanraragi/content"
        "/tank/documents/lanraragi/thumb:/home/koyomi/lanraragi/thumb"
      ];
    };
  };
}
