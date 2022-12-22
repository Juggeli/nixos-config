{ options, config, pkgs, lib, ... }:

with lib;
with lib.my;
let cfg = config.modules.services.tailscale;
in
{
  options.modules.services.tailscale = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.tailscale = {
      enable = true;
    };

    networking.firewall = {
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ config.services.tailscale.port ];
      checkReversePath = "loose";
    };

    systemd.services.tailscale-autoconnect = {
      description = "Automatic connection to Tailscale";
      after = [ "network-pre.target" "tailscale.service" ];
      wants = [ "network-pre.target" "tailscale.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script = with pkgs; ''
        # wait for tailscaled to settle
        sleep 2

        # check if we are already authenticated to tailscale
        status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
        if [ $status = "Running" ]; then # if so, then do nothing
          exit 0
        fi

        # otherwise authenticate with tailscale
        ${tailscale}/bin/tailscale up -authkey tskey-auth-kvjL3X7CNTRL-8wTKFN2Uu1JeZeuJzf26vHZoCN1GTh8cd
      '';
    };
  };
}

