{
  flake.nixosModules.haruka-tailscale-serve =
    {
      config,
      lib,
      ...
    }:
    let
      # Containers publish on loopback only, so anything without a Cloudflare
      # tunnel hostname needs a tailnet path to stay reachable. The *arrs and
      # memos are omitted deliberately: the tunnel already serves them.
      servedPorts = [
        3000 # homepage
        3333 # lanraragi
        6767 # bazarr
        8000 # sillytavern
        8080 # qbittorrent
        8384 # syncthing gui
        9696 # prowlarr
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
