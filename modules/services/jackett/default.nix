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
    services.jackett = {
      enable = true;
      openFirewall = true;
      dataDir = "/mnt/appdata/jackett";
    };
  };
}
