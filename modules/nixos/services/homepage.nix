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
    widgets = mkOpt (types.attrsOf types.anything) {} "Widgets configuration for homepage dashboard";
    services = mkOpt (types.attrsOf types.anything) {} "Services configuration for homepage dashboard";
    settings = mkOpt (types.attrsOf types.anything) {} "Additional settings for homepage dashboard";
    listenPort = mkOpt types.port 3000 "Port for homepage dashboard to listen on";
  };

  config = mkIf cfg.enable {
    services.homepage-dashboard = {
      enable = true;
      listenPort = cfg.listenPort;
      openFirewall = cfg.openFirewall;
      widgets = cfg.widgets;
      services = cfg.services;
      settings = cfg.settings;
    };
  };
}