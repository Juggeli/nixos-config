{ options, config, pkgs, lib, ... }:

with lib;
with lib.internal;
let cfg = config.plusultra.services.jackett;
in
{
  options.plusultra.services.jackett = with types; {
    enable = mkBoolOpt false "Whether or not to jackett service.";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.jackett = {
      image = "cr.hotio.dev/hotio/jackett";
      autoStart = true;
      ports = [ "9117:9117" ];
      volumes = [
        "/mnt/appdata/jackett/:/config"
      ];
    };
  };
}
