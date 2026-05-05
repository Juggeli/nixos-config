{
  flake.nixosModules.haruka-cleanup =
    { config, pkgs, ... }:
    let
      radarrWhitelist = pkgs.writeText "radarr-cleanup-whitelist" ''
        Survive Style 5+
        Battle Royale
      '';
    in
    {
      systemd.services.sonarr-cleanup = {
        description = "Sonarr unwatched series cleanup";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.sonarr-cleanup}/bin/sonarr-cleanup";
          StateDirectory = "sonarr-cleanup";
          Environment = [
            "SONARR_URL=http://10.11.11.2:8989"
            "SONARR_API_KEY_FILE=${config.age.secrets.sonarr-api.path}"
            "THRESHOLD_DAYS=730"
            "GRACE_PERIOD_DAYS=7"
            "STATE_FILE=/var/lib/sonarr-cleanup/state.json"
            "DRY_RUN=false"
            "JELLYFIN_URL=http://10.11.11.2:8096"
            "JELLYFIN_API_KEY_FILE=${config.age.secrets.jellyfin-api.path}"
            "PLEX_URL=http://10.11.11.2:32400"
            "PLEX_TOKEN_FILE=${config.age.secrets.plex-token.path}"
            "NTFY_TOPIC_FILE=${config.age.secrets.ntfy-topic.path}"
          ];
        };
      };

      systemd.timers.sonarr-cleanup = {
        description = "Timer for Sonarr cleanup service";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*-*-* 03:00:00";
          Persistent = true;
          RandomizedDelaySec = "1h";
        };
      };

      systemd.services.sonarr-anime-cleanup = {
        description = "Sonarr anime fully-watched series cleanup";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.sonarr-anime-cleanup}/bin/sonarr-anime-cleanup";
          StateDirectory = "sonarr-anime-cleanup";
          Environment = [
            "SONARR_URL=http://10.11.11.2:8999"
            "SONARR_API_KEY_FILE=${config.age.secrets.sonarr-anime-api.path}"
            "JELLYFIN_URL=http://10.11.11.2:8096"
            "JELLYFIN_API_KEY_FILE=${config.age.secrets.jellyfin-api.path}"
            "JELLYFIN_USERNAME=juggeli"
            "THRESHOLD_DAYS=365"
            "GRACE_PERIOD_DAYS=7"
            "STATE_FILE=/var/lib/sonarr-anime-cleanup/state.json"
            "DRY_RUN=false"
            "NTFY_TOPIC_FILE=${config.age.secrets.ntfy-topic.path}"
          ];
        };
      };

      systemd.timers.sonarr-anime-cleanup = {
        description = "Timer for Sonarr anime cleanup service";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*-*-* 03:30:00";
          Persistent = true;
          RandomizedDelaySec = "1h";
        };
      };

      systemd.services.radarr-cleanup = {
        description = "Radarr unwatched movie cleanup";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.radarr-cleanup}/bin/radarr-cleanup";
          StateDirectory = "radarr-cleanup";
          Environment = [
            "RADARR_URL=http://10.11.11.2:7878"
            "RADARR_API_KEY_FILE=${config.age.secrets.radarr-api.path}"
            "THRESHOLD_DAYS=730"
            "GRACE_PERIOD_DAYS=7"
            "STATE_FILE=/var/lib/radarr-cleanup/state.json"
            "DRY_RUN=false"
            "JELLYFIN_URL=http://10.11.11.2:8096"
            "JELLYFIN_API_KEY_FILE=${config.age.secrets.jellyfin-api.path}"
            "PLEX_URL=http://10.11.11.2:32400"
            "PLEX_TOKEN_FILE=${config.age.secrets.plex-token.path}"
            "NTFY_TOPIC_FILE=${config.age.secrets.ntfy-topic.path}"
            "WHITELIST_FILE=${radarrWhitelist}"
          ];
        };
      };

      systemd.timers.radarr-cleanup = {
        description = "Timer for Radarr cleanup service";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*-*-* 04:00:00";
          Persistent = true;
          RandomizedDelaySec = "1h";
        };
      };
    };
}
