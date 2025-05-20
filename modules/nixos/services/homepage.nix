{ config, lib, ... }:

with lib;
with lib.plusultra;
let
  cfg = config.plusultra.services.homepage;
in
{
  options.plusultra.services.homepage = with types; {
    enable = mkBoolOpt false "Whether or not to enable homepage dashboard service.";
    openFirewall = mkEnableOption "Open the firewall for homepage";
  };

  config = mkIf cfg.enable {
    services.homepage-dashboard = {
      enable = true;
      listenPort = 3000;
      openFirewall = cfg.openFirewall;
    };
  };
}