{
  flake.nixosModules.haruka-qbittorrent-manager =
    { config, pkgs, ... }:
    let
      configFile = pkgs.writeTextFile {
        name = "qbit-manager-config.json";
        text = builtins.toJSON {
          host = "10.11.11.2";
          port = 8080;
          public_ratio_limit = 2.0;
          upload_limit_downloading = 200000;
          arr_categories = [
            "sonarr-done"
            "sonarr-anime-done"
            "radarr-done"
            "radarr-anime-done"
          ];
        };
      };
    in
    {
      users.users.qbit-manager = {
        isSystemUser = true;
        group = "qbit-manager";
        description = "qBittorrent manager service user";
      };
      users.groups.qbit-manager = { };

      systemd.services.qbittorrent-manager = {
        description = "qBittorrent management service";
        after = [ "network.target" ];
        serviceConfig = {
          Type = "oneshot";
          User = "qbit-manager";
          Group = "qbit-manager";
          ExecStart = "${pkgs.qbit-manager}/bin/qbit-manager --config ${configFile}";
          EnvironmentFile = config.age.secrets.qbittorrent-credentials.path;

          NoNewPrivileges = true;
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectHome = true;
          ProtectClock = true;
          ProtectProc = "invisible";
          ProcSubset = "pid";
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectControlGroups = true;
          ProtectHostname = true;
          RestrictSUIDSGID = true;
          RestrictRealtime = true;
          RestrictNamespaces = true;
          LockPersonality = true;
          RemoveIPC = true;
          SystemCallFilter = [
            "@system-service"
            "~@privileged"
          ];
          SystemCallArchitectures = "native";
          UMask = "0077";
        };
      };

      systemd.timers.qbittorrent-manager = {
        description = "qBittorrent management timer";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "minutely";
          Persistent = true;
          RandomizedDelaySec = "5min";
        };
      };
    };
}
