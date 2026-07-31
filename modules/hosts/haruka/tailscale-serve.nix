{
  flake.nixosModules.haruka-tailscale-serve =
    {
      config,
      lib,
      ...
    }:
    let
      # Loopback-only services that need a tailnet path. The arr stack and
      # qbittorrent are omitted: they bind wide and are admitted from
      # tailscale0 by the firewall, and a serve listener on the same port
      # would shadow the container's bind on the tailnet address.
      servedPorts = [
        8384 # syncthing gui
        8091 # portion-calculator
      ];

      tailscale = "${config.services.tailscale.package}/bin/tailscale";
    in
    {
      systemd.services.tailscale-serve = {
        description = "Publish loopback-only services on the tailnet";
        after = [ "tailscaled.service" ];
        wants = [ "tailscaled.service" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };

        # Dropping a port from servedPorts does not retract it; the serve config
        # lives in tailscaled state. Retire one with `tailscale serve --https=N off`.
        script = ''
          for _ in $(seq 1 60); do
            ${tailscale} status >/dev/null 2>&1 && break
            sleep 2
          done

          ${lib.concatMapStringsSep "\n" (port: ''
            ${tailscale} serve --bg --https=${toString port} http://127.0.0.1:${toString port}
          '') servedPorts}
        '';
      };
    };
}
