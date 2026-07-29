{
  flake.nixosModules.haruka-cloudflared =
    { config, ... }:
    let
      # Created with `cloudflared tunnel create`, so it carries no configuration
      # on Cloudflare's side and the ingress below is the only source of truth.
      # A dashboard-created tunnel would silently override all of this.
      tunnelId = "03b1c5a5-383a-4096-b567-ac3e4f9430c6";
    in
    {
      services.cloudflared = {
        enable = true;

        tunnels.${tunnelId} = {
          credentialsFile = config.age.secrets.cloudflared-credentials.path;
          default = "http_status:404";
          edgeIPVersion = "auto";

          ingress = {
            "sonarr.jugi.cc" = "http://127.0.0.1:8989";
            "sonarr-anime.jugi.cc" = "http://127.0.0.1:8999";
            "radarr.jugi.cc" = "http://127.0.0.1:7878";
            "radarr-anime.jugi.cc" = "http://127.0.0.1:7879";
            "jelly.jugi.cc" = "http://127.0.0.1:8096";
            "plex.jugi.cc" = "http://127.0.0.1:32400";
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
