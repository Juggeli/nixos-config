{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.services.tailscale;
in
{
  options.plusultra.services.tailscale = with types; {
    enable = mkBoolOpt false "Whether or not to configure Tailscale";
    autoconnect = {
      enable = mkBoolOpt false "Whether or not to enable automatic connection to Tailscale";
      key = mkOpt str "" "The authentication key to use";
    };
    port = mkOpt types.int 41641 "Custom port for tailscale";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.autoconnect.enable -> cfg.autoconnect.key != "";
        message = "plusultra.services.tailscale.autoconnect.key must be set";
      }
    ];

    environment.systemPackages = with pkgs; [ tailscale ];

    services.tailscale = {
      enable = true;
      port = cfg.port;
      authKeyFile = mkIf cfg.autoconnect.enable cfg.autoconnect.key;
    };

    # TODO: Remove this when tailscale fixes their logging
    systemd.services.tailscaled.serviceConfig.StandardOutput = "null";

    plusultra.filesystem.impermanence.directories = [
      "/var/lib/tailscale"
    ];

    # Enable ip forwarding for app connector
    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
    boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = 1;

    networking = {
      firewall = {
        trustedInterfaces = [ config.services.tailscale.interfaceName ];

        allowedUDPPorts = [ config.services.tailscale.port ];

        # Strict reverse path filtering breaks Tailscale exit node use and some subnet routing setups.
        checkReversePath = "loose";
      };

      networkmanager.unmanaged = [ "tailscale0" ];
    };
  };
}
