{ options, config, pkgs, lib, ... }:

with lib;
with lib.internal;
let cfg = config.plusultra.services.sonarr;
in
{
  options.plusultra.services.sonarr = with types; {
    enable = mkBoolOpt false "Whether or not to enable sonarr service.";
  };

  config = mkIf cfg.enable {
    services.sonarr = {
      enable = true;
      openFirewall = true;
      dataDir = "/mnt/appdata/sonarr";
    };
  };
}
