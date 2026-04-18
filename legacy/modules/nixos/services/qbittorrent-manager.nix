{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.plusultra;

let
  cfg = config.plusultra.services.qbittorrent-manager;

  configFile = pkgs.writeTextFile {
    name = "qbit-manager-config.json";
    text = builtins.toJSON {
      host = cfg.connection.host;
      port = cfg.connection.port;
      public_ratio_limit = cfg.limits.publicRatio;
      upload_limit_downloading = cfg.limits.uploadLimitDownloading;
      arr_categories = cfg.cleanup.arrCategories;
    };
  };

  qbit-manager = pkgs.callPackage ../../../packages/qbit-manager { };
in
{
  options.plusultra.services.qbittorrent-manager = with types; {
    enable = mkEnableOption "qBittorrent manager service";

    connection = {
      host = mkOption {
        type = str;
        default = "localhost";
        description = "qBittorrent host";
      };

      port = mkOption {
        type = port;
        default = 8080;
        description = "qBittorrent port";
      };

      credentialsFile = mkOption {
        type = path;
        description = "Path to file containing username and password (JSON format with 'username' and 'password' keys)";
      };
    };

    limits = {
      publicRatio = mkOption {
        type = float;
        default = 2.0;
        description = "Share ratio limit for public torrents";
      };

      uploadLimitDownloading = mkOption {
        type = int;
        default = 200000;
        description = "Upload speed limit (bytes/s) for downloading public torrents";
      };
    };

    cleanup = {
      arrCategories = mkOption {
        type = listOf str;
        default = [
          "sonarr-done"
          "sonarr-anime-done"
          "radarr-done"
          "radarr-anime-done"
        ];
        description = "Post-import categories to clean up completed torrents from (beyond 'Public')";
        example = [
          "sonarr-done"
          "radarr-done"
          "prowlarr-done"
        ];
      };
    };

    schedule = mkOption {
      type = str;
      default = "minutely";
      description = "systemd timer schedule (OnCalendar format)";
      example = "*:0/5";
    };

    user = mkOption {
      type = str;
      default = "qbit-manager";
      description = "User to run the service as";
    };

    group = mkOption {
      type = str;
      default = "qbit-manager";
      description = "Group to run the service as";
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      description = "qBittorrent manager service user";
    };

    users.groups.${cfg.group} = { };

    systemd.services.qbittorrent-manager = {
      description = "qBittorrent management service";
      after = [ "network.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${qbit-manager}/bin/qbit-manager --config ${configFile}";
        EnvironmentFile = cfg.connection.credentialsFile;

        # Security hardening
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
        OnCalendar = cfg.schedule;
        Persistent = true;
        RandomizedDelaySec = "5min";
      };
    };
  };
}
