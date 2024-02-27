{ lib, pkgs, config, ... }:
with lib;
with lib.plusultra; let
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
    };

    plusultra.filesystem.impermanence.directories = mkIf config.plusultra.filesystem.impermanence.enable [
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

    systemd.services.tailscale-autoconnect = mkIf cfg.autoconnect.enable {
      description = "Automatic connection to Tailscale";

      # Make sure tailscale is running before trying to connect to tailscale
      after = [ "network-pre.target" "tailscale.service" ];
      wants = [ "network-pre.target" "tailscale.service" ];
      wantedBy = [ "multi-user.target" ];

      # Set this service as a oneshot job
      serviceConfig.Type = "oneshot";

      # Have the job run this shell script
      script = with pkgs; ''
        # Wait for tailscaled to settle
        sleep 2
        # Check if we are already authenticated to tailscale
        status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
        if [ $status = "Running" ]; then # if so, then do nothing
          exit 0
        fi
        # Otherwise authenticate with tailscale
        ${tailscale}/bin/tailscale up -authkey "${cfg.autoconnect.key}"
      '';
    };
  };
}
