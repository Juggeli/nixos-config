{ options, config, lib, ... }:

with lib;
with lib.my;
let cfg = config.modules.services.unifi;
in {
  options.modules.services.unifi = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.unifi = {
      enable = true;
      openFirewall = true;
    };

    networking.firewall.allowedTCPPorts = [ 8443 ];
  };
}

