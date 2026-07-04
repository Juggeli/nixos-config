{
  flake.nixosModules.tailscale =
    { config, pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.tailscale ];

      services.tailscale = {
        enable = true;
        port = 41641;
      };

      systemd.services.tailscaled.serviceConfig.StandardOutput = "null";

      environment.persistence."/persist".directories = [ "/var/lib/tailscale" ];

      boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
      boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = 1;

      networking = {
        firewall = {
          trustedInterfaces = [ config.services.tailscale.interfaceName ];
          allowedUDPPorts = [ config.services.tailscale.port ];
          checkReversePath = "loose";
        };
        networkmanager.unmanaged = [ "tailscale0" ];
      };
    };
}
