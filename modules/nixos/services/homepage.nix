{ config, lib, ... }:

with lib;
with lib.plusultra;
let
  cfg = config.plusultra.services.homepage;
  
  # Get all service definitions
  allServices = config.plusultra._module.args.plusultra.homepage.services or {};
  
  # Format services for the homepage-dashboard module
  formatServices = 
    if allServices == {} then []
    else
      let
        # Group services by category
        groupedServices = foldAttrs (item: acc: acc ++ item) [] allServices;
      in
        # Convert to list of category entries as expected by homepage-dashboard
        map (category: { "${category.name}" = category.value; }) 
          (mapAttrsToList (name: value: { name = name; value = value; }) groupedServices);
in
{
  options = {
    plusultra.services.homepage = with types; {
      enable = mkBoolOpt false "Whether or not to enable homepage dashboard service.";
      openFirewall = mkEnableOption "Open the firewall for homepage";
      widgets = mkOpt (types.listOf types.anything) [] "Widgets configuration for homepage dashboard";
      settings = mkOpt (types.attrsOf types.anything) {} "Additional settings for homepage dashboard";
      listenPort = mkOpt types.port 3000 "Port for homepage dashboard to listen on";
    };
    
    # Hidden option for collecting service definitions from modules
    plusultra._module.args.plusultra.homepage.services = mkOption {
      internal = true;
      default = {};
    };
  };

  config = mkIf cfg.enable {
    services.homepage-dashboard = {
      enable = true;
      listenPort = cfg.listenPort;
      openFirewall = cfg.openFirewall;
      widgets = cfg.widgets;
      services = formatServices;
      settings = cfg.settings;
    };
  };
}