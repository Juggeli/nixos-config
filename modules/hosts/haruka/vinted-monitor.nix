{
  flake.nixosModules.haruka-vinted-monitor =
    { config, pkgs, ... }:
    {
      systemd.services.vinted-monitor = {
        description = "Vinted search new listing notifier";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.vinted-monitor}/bin/vinted-monitor";
          DynamicUser = true;
          StateDirectory = "vinted-monitor";
          LoadCredential = "ntfy-topic:${config.age.secrets.vinted-ntfy-topic.path}";
          Environment = [
            "VINTED_SEARCH_URL=https://www.vinted.fi/catalog?catalog[]=2050&size_ids[]=209&size_ids[]=210&brand_ids[]=358956"
            "STATE_FILE=/var/lib/vinted-monitor/state.json"
            "NTFY_TOPIC_FILE=%d/ntfy-topic"
          ];
        };
      };

      systemd.timers.vinted-monitor = {
        description = "Timer for Vinted search notifier";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*:0/5";
          RandomizedDelaySec = "60";
        };
      };
    };
}
