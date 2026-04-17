{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.services.sonarr-anime-cleanup;
  whitelistFile = pkgs.writeText "sonarr-anime-cleanup-whitelist" (
    concatStringsSep "\n" cfg.whitelist
  );
in
{
  options.plusultra.services.sonarr-anime-cleanup = with types; {
    enable = mkBoolOpt false "Whether to enable the Sonarr anime cleanup service.";

    sonarr = {
      url = mkOption {
        type = str;
        default = "http://localhost:8999";
        description = "Sonarr anime URL";
      };
      apiKeyFile = mkOption {
        type = path;
        description = "Path to file containing Sonarr API key";
      };
    };

    jellyfin = {
      url = mkOption {
        type = str;
        default = "http://localhost:8096";
        description = "Jellyfin URL";
      };
      apiKeyFile = mkOption {
        type = path;
        description = "Path to file containing Jellyfin API key";
      };
      username = mkOption {
        type = str;
        description = "Jellyfin username to check watch status for";
      };
    };

    threshold = mkOption {
      type = int;
      default = 365;
      description = "Days since last watch to consider for cleanup";
    };

    gracePeriod = mkOption {
      type = int;
      default = 7;
      description = "Days to wait before deletion after marking";
    };

    stateFile = mkOption {
      type = str;
      default = "/var/lib/sonarr-anime-cleanup/state.json";
      description = "Path to state file tracking pending deletions";
    };

    ntfy = {
      enable = mkBoolOpt true "Whether to enable ntfy notifications.";
      topicFile = mkOption {
        type = nullOr path;
        default = null;
        description = "Path to file containing ntfy topic";
      };
    };

    schedule = mkOption {
      type = str;
      default = "*-*-* 03:30:00";
      description = "Systemd OnCalendar schedule (default: daily at 3:30 AM)";
    };

    dryRun = mkBoolOpt true "Run in dry-run mode (no actual deletions). Set to false to enable real deletions.";

    whitelist = mkOption {
      type = listOf str;
      default = [ ];
      description = "List of series titles to exclude from cleanup (case-insensitive)";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.ntfy.enable -> cfg.ntfy.topicFile != null;
        message = "ntfy topic file must be set when ntfy is enabled";
      }
    ];

    systemd.services.sonarr-anime-cleanup = {
      description = "Sonarr anime fully-watched series cleanup";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.plusultra.sonarr-anime-cleanup}/bin/sonarr-anime-cleanup";
        StateDirectory = "sonarr-anime-cleanup";
        Environment = [
          "SONARR_URL=${cfg.sonarr.url}"
          "SONARR_API_KEY_FILE=${cfg.sonarr.apiKeyFile}"
          "JELLYFIN_URL=${cfg.jellyfin.url}"
          "JELLYFIN_API_KEY_FILE=${cfg.jellyfin.apiKeyFile}"
          "JELLYFIN_USERNAME=${cfg.jellyfin.username}"
          "THRESHOLD_DAYS=${toString cfg.threshold}"
          "GRACE_PERIOD_DAYS=${toString cfg.gracePeriod}"
          "STATE_FILE=${cfg.stateFile}"
          "DRY_RUN=${if cfg.dryRun then "true" else "false"}"
        ]
        ++ optionals cfg.ntfy.enable [
          "NTFY_TOPIC_FILE=${cfg.ntfy.topicFile}"
        ]
        ++ optionals (cfg.whitelist != [ ]) [
          "WHITELIST_FILE=${whitelistFile}"
        ];
      };
    };

    systemd.timers.sonarr-anime-cleanup = {
      description = "Timer for Sonarr anime cleanup service";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.schedule;
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };
  };
}
