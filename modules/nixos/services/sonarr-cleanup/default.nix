{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.services.sonarr-cleanup;
in
{
  options.plusultra.services.sonarr-cleanup = with types; {
    enable = mkBoolOpt false "Whether to enable the Sonarr cleanup service.";

    sonarr = {
      url = mkOption {
        type = str;
        default = "http://localhost:8989";
        description = "Sonarr URL";
      };
      apiKeyFile = mkOption {
        type = path;
        description = "Path to file containing Sonarr API key";
      };
    };

    jellyfin = {
      enable = mkBoolOpt true "Whether to use Jellyfin for watch history.";
      url = mkOption {
        type = str;
        default = "http://localhost:8096";
        description = "Jellyfin URL";
      };
      apiKeyFile = mkOption {
        type = nullOr path;
        default = null;
        description = "Path to file containing Jellyfin API key";
      };
    };

    plex = {
      enable = mkBoolOpt false "Whether to use Plex for watch history.";
      url = mkOption {
        type = str;
        default = "http://localhost:32400";
        description = "Plex URL";
      };
      tokenFile = mkOption {
        type = nullOr path;
        default = null;
        description = "Path to file containing Plex token";
      };
    };

    threshold = mkOption {
      type = int;
      default = 730;
      description = "Days since last watch to consider unwatched";
    };

    gracePeriod = mkOption {
      type = int;
      default = 7;
      description = "Days to wait before deletion after marking";
    };

    stateFile = mkOption {
      type = str;
      default = "/var/lib/sonarr-cleanup/state.json";
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
      default = "*-*-* 03:00:00";
      description = "Systemd OnCalendar schedule (default: daily at 3 AM)";
    };

    dryRun = mkBoolOpt true "Run in dry-run mode (no actual deletions). Set to false to enable real deletions.";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.jellyfin.enable -> cfg.jellyfin.apiKeyFile != null;
        message = "Jellyfin API key file must be set when Jellyfin is enabled";
      }
      {
        assertion = cfg.plex.enable -> cfg.plex.tokenFile != null;
        message = "Plex token file must be set when Plex is enabled";
      }
      {
        assertion = cfg.jellyfin.enable || cfg.plex.enable;
        message = "At least one media server (Jellyfin or Plex) must be enabled";
      }
      {
        assertion = cfg.ntfy.enable -> cfg.ntfy.topicFile != null;
        message = "ntfy topic file must be set when ntfy is enabled";
      }
    ];

    systemd.services.sonarr-cleanup = {
      description = "Sonarr unwatched series cleanup";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.plusultra.sonarr-cleanup}/bin/sonarr-cleanup";
        StateDirectory = "sonarr-cleanup";
        Environment =
          [
            "SONARR_URL=${cfg.sonarr.url}"
            "SONARR_API_KEY_FILE=${cfg.sonarr.apiKeyFile}"
            "THRESHOLD_DAYS=${toString cfg.threshold}"
            "GRACE_PERIOD_DAYS=${toString cfg.gracePeriod}"
            "STATE_FILE=${cfg.stateFile}"
            "DRY_RUN=${if cfg.dryRun then "true" else "false"}"
          ]
          ++ optionals cfg.jellyfin.enable [
            "JELLYFIN_URL=${cfg.jellyfin.url}"
            "JELLYFIN_API_KEY_FILE=${cfg.jellyfin.apiKeyFile}"
          ]
          ++ optionals cfg.plex.enable [
            "PLEX_URL=${cfg.plex.url}"
            "PLEX_TOKEN_FILE=${cfg.plex.tokenFile}"
          ]
          ++ optionals cfg.ntfy.enable [
            "NTFY_TOPIC_FILE=${cfg.ntfy.topicFile}"
          ];
      };
    };

    systemd.timers.sonarr-cleanup = {
      description = "Timer for Sonarr cleanup service";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.schedule;
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };
  };
}
