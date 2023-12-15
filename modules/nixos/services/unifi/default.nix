{
  options,
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.services.unifi;
in {
  options.plusultra.services.unifi = with types; {
    enable = mkBoolOpt false "Whether or not to enable unifi service.";
  };

  config = mkIf cfg.enable {
    services.unifi = {
      enable = true;
      unifiPackage = pkgs.unifi;
      openFirewall = true;
    };

    networking.firewall.allowedTCPPorts = [8443];
  };
}
