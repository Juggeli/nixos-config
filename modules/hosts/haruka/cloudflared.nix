{
  flake.nixosModules.haruka-cloudflared =
    { config, ... }:
    let
      tunnelId = "2c4475e1-77e4-46bd-aabe-42a265cec5fd";
    in
    {
      services.cloudflared = {
        enable = true;

        tunnels.${tunnelId} = {
          credentialsFile = config.age.secrets.cloudflared-credentials.path;
          default = "http_status:404";
          edgeIPVersion = "auto";

          # Cloudflare still serves a remote configuration for this tunnel, and
          # remote config wins over the local file. These rules therefore mirror
          # the dashboard rather than drive it; they only become authoritative
          # once the tunnel's remote configuration is cleared via the API
          # (PUT /accounts/:account/cfd_tunnel/:tunnel/configurations), which
          # leaves the DNS records intact.
          ingress = {
            "sonarr.jugi.cc" = "http://127.0.0.1:8989";
            "sonarr-anime.jugi.cc" = "http://127.0.0.1:8999";
            "radarr.jugi.cc" = "http://127.0.0.1:7878";
            "radarr-anime.jugi.cc" = "http://127.0.0.1:7879";
            "jelly.jugi.cc" = "http://127.0.0.1:8096";
            "memos.jugi.cc" = "http://127.0.0.1:5230";
          };
        };
      };

      # DynamicUser already implies NoNewPrivileges, RestrictSUIDSGID, PrivateTmp,
      # ProtectSystem=strict and ProtectHome=read-only. AF_NETLINK is required for
      # the interface enumeration cloudflared does to pick an ICMP proxy source.
      systemd.services."cloudflared-tunnel-${tunnelId}".serviceConfig = {
        CapabilityBoundingSet = "";
        DevicePolicy = "closed";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        PrivateDevices = true;
        ProcSubset = "pid";
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_NETLINK"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
          "~@obsolete"
        ];
        UMask = "0077";
      };
    };
}
