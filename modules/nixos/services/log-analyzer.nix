{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.plusultra;

let
  cfg = config.plusultra.services.log-analyzer;

  analyzerScript = pkgs.writeShellScript "log-analyzer" ''
        set -euo pipefail

        API_KEY=$(cat "${cfg.apiKeyFile}")
        OUTPUT_DIR="${cfg.outputDir}"
        REPORT_FILE="$OUTPUT_DIR/$(date +%Y-%m-%d).md"
        HOURS_BACK="${toString cfg.hoursBack}"
        MAX_LINES="${toString cfg.maxLines}"
        MAX_DUPES="${toString cfg.maxDuplicates}"
        MODEL="${cfg.model}"

        TMPDIR=$(mktemp -d)
        trap "rm -rf $TMPDIR" EXIT

        mkdir -p "$OUTPUT_DIR"

        echo "Collecting logs from the last $HOURS_BACK hours..."

        ${pkgs.systemd}/bin/journalctl \
          --since "$HOURS_BACK hours ago" \
          --no-pager \
          -o short-iso \
          --no-hostname \
          ${optionalString (cfg.priorityFilter != null) "-p ${cfg.priorityFilter}"} \
          2>/dev/null > "$TMPDIR/raw_logs.txt" || true

        if [ ! -s "$TMPDIR/raw_logs.txt" ]; then
          echo "No logs found"
          exit 0
        fi

        echo "Filtering noisy log patterns..."

        ${pkgs.gnugrep}/bin/grep -v \
          -e "Starting .*.service\.\.\." \
          -e "Finished .*.service\." \
          -e "Deactivated successfully\." \
          -e "Consumed .*CPU time.*memory peak" \
          -e "systemd-timesyncd.*Contacted time server" \
          -e "nix-gc.*deleting" \
          -e "dhcpcd.*adding route to" \
          -e "dhcpcd.*deleting route to" \
          -e "dhcpcd.*dhcp_envoption.*malformed" \
          -e "zed\[.*\]: eid=.*class=history_event" \
          -e "sonarr.*\[Info\]" \
          -e "radarr.*\[Info\]" \
          -e "prowlarr.*\[Info\]" \
          -e "bazarr.*\[Info\]" \
          -e "lidarr.*\[Info\]" \
          -e "readarr.*\[Info\]" \
          -e "jellyfin.*\[INF\]" \
          -e "podman0: port .*(veth.*).*state" \
          -e "Reached target.*Lookups" \
          -e "Stopped target.*Lookups" \
          -e "Stopped target.*podman auto-update" \
          -e "ApiKeyAuthenticationHandler: AuthenticationScheme: API was challenged" \
          -e "Trailing option(s) found in the command: may be ignored" \
          -e "smartd.*SMART.*Attribute:.*changed from" \
          -e "syncthing.*\[.*\].*: " \
          -e "sillytavern\[.*\]:" \
          -e "IntroSkipper.*Running enqueue of items" \
          -e "IntroSkipper.*Analyzing .* files from" \
          -e "IntroSkipper.*Initiating automatic analysis" \
          -e "will be refreshed\.$" \
          -e "Starting ZFS auto-snapshotting" \
          -e "Finished ZFS auto-snapshotting" \
          -e "Starting Logrotate Service" \
          -e "Finished Logrotate Service" \
          -e "\[Info\] HousekeepingService: Running housecleaning" \
          -e "\[Info\] Database: Vacuuming" \
          -e "\[Info\] Database:.*compressed" \
          -e "pam_unix(sshd:session): session opened" \
          -e "pam_unix(sshd:session): session closed" \
          -e "^[[:space:]]*$" \
          -e "<[^>]*>" \
          -e "podman-auto-update.*UNIT.*CONTAINER.*IMAGE" \
          -e "podman-.*\.service.*\(.*\).*ghcr\.io\|docker\.io" \
          -e "ata[0-9].*status:.*DRDY" \
          -e "ata[0-9].*supports DRM functions" \
          -e "ata[0-9].*configured for UDMA" \
          -e "ata[0-9].*SATA link up" \
          -e "ata[0-9]: SError:" \
          -e "ata[0-9]: EH complete" \
          -e "res 40/.*Emask 0x4 (timeout)" \
          -e "\[Info\] RecycleBinProvider: Recycle Bin has not been configured" \
          -e "\[Info\] BackupService: Starting Backup" \
          -e "INFO Remote:.*WARNING.*post-quantum" \
          -e "INFO Remote:.*store now, decrypt later" \
          -e "INFO Remote:.*openssh.com/pq.html" \
          -e "^.*-\{10,\}$" \
          -e "The deprecated BoltDB database driver" \
          -e "\[Info\] AppFolderInfo: Data directory is being overridden" \
          -e "\[Info\] NzbDrone.Core.Datastore.Migration" \
          -e "\[Info\] FluentMigrator.Runner.MigrationRunner" \
          -e "s6-rc: info: service" \
          -e "Stopping libcrun container" \
          -e "Stopped libcrun container" \
          -e "Started libcrun container" \
          -e "usermod: no changes" \
          -e "Network configuration changed, trying to establish" \
          -e ": UNBOUND_" \
          -e ": UMASK=" \
          -e ": TZ=" \
          -e ": PUID=" \
          -e ": PGID=" \
          -e ": VPN_ENABLED=" \
          -e ": PRIVOXY_ENABLED=" \
          -e ": ENVIRONMENT " \
          -e ": OS:.*Linux" \
          -e "hotio.dev" \
          -e "Executing usermod" \
          -e "Applying permissions to" \
          -e "/run/s6/basedir/scripts/rc.init" \
          -e " _           _   _" \
          -e "| '_ \.* / _ \\\\" \
          -e "|_| |_|" \
          -e "| |__   ___ " \
          -e "Started Session .* of User" \
          -e "New session .* of user .* with class" \
          -e "Session .* logged out" \
          -e "Removed session" \
          -e "Accepted publickey for" \
          -e "Received disconnect from" \
          -e "Disconnected from user" \
          -e "^.*   at System\." \
          -e "^.*   at Microsoft\." \
          -e "^.*   at Jellyfin\." \
          -e "^.*   at Emby\." \
          -e "^.*   at BlurHashSharp\." \
          -e "^.*   at NzbDrone\." \
          -e "^.* --- End of inner exception" \
          -e "^.* ---> System\." \
          -e "\[Info\] MigrationController: \*\*\* Migrating" \
          -e "\[Info\] Microsoft.Hosting.Lifetime: Application is shutting down" \
          -e "\[Info\] DatabaseEngineVersionCheck: SQLite" \
          -e "\[Debug\] Bootstrap: Console selected" \
          -e "| | | | (_) |" \
          -e "^.*|.*|.*|.*|$" \
          -e "\[Info\] Microsoft.Hosting.Lifetime: Hosting environment" \
          -e "\[Info\] Microsoft.Hosting.Lifetime: Content root path" \
          -e "\[Info\] Microsoft.Hosting.Lifetime: Application started" \
          -e "\[Info\] ManagedHttpDispatcher: IPv. is available" \
          -e "\[Info\] ConsoleApp: Exiting main" \
          -e "\[Info\] Bootstrap: Starting" \
          -e "^.*PRAGMA " \
          -e "^.*APM_level" \
          -e "^.*setting standby to" \
          -e "^.*setting Advanced Power Management" \
          -e "ACPI: Dynamic OEM Table Load" \
          ${concatMapStringsSep " " (p: ''-e "${p}"'') cfg.extraFilterPatterns} \
          "$TMPDIR/raw_logs.txt" > "$TMPDIR/filtered_logs.txt" || true

        FILTERED_COUNT=$(($(wc -l < "$TMPDIR/raw_logs.txt") - $(wc -l < "$TMPDIR/filtered_logs.txt")))
        echo "Filtered out $FILTERED_COUNT noisy log lines"

        echo "Deduplicating logs..."

        ${pkgs.gawk}/bin/awk -v max_dupes="$MAX_DUPES" '
        {
          ts = $1 " " $2
          $1 = ""; $2 = ""
          msg = $0
          gsub(/^[[:space:]]+/, "", msg)

          if (msg in count) {
            count[msg]++
            if (count[msg] <= max_dupes) {
              lines[msg] = lines[msg] "\n" ts " " msg
            }
          } else {
            count[msg] = 1
            first_ts[msg] = ts
            lines[msg] = ts " " msg
            order[++n] = msg
          }
        }
        END {
          for (i = 1; i <= n; i++) {
            msg = order[i]
            print lines[msg]
            if (count[msg] > max_dupes) {
              printf "[... repeated %d more times]\n", count[msg] - max_dupes
            }
          }
        }' "$TMPDIR/filtered_logs.txt" > "$TMPDIR/deduped_logs.txt"

        TOTAL_LINES=$(wc -l < "$TMPDIR/deduped_logs.txt")
        echo "Total lines after dedup: $TOTAL_LINES"

        if [ "$TOTAL_LINES" -gt "$MAX_LINES" ]; then
          echo "Truncating to $MAX_LINES lines..."
          tail -n "$MAX_LINES" "$TMPDIR/deduped_logs.txt" > "$TMPDIR/truncated_logs.txt"
          mv "$TMPDIR/truncated_logs.txt" "$TMPDIR/deduped_logs.txt"
        fi

        echo "Sending logs to LLM for analysis..."

        SYSTEM_PROMPT="You are a system administrator analyzing logs from a home server running NixOS.
    The server runs various media services (Plex, Jellyfin, Sonarr, Radarr, Bazarr, qBittorrent, etc.) as Podman containers, plus system services like ZFS, Borgmatic backups, Syncthing, and Cloudflared.

    Analyze these logs from the last $HOURS_BACK hours and provide:

    1. **Critical Issues** - Errors requiring immediate attention
    2. **Warnings** - Problems that should be addressed soon
    3. **Notable Events** - Interesting patterns or unusual activity
    4. **Health Summary** - Overall system health assessment (1-2 sentences)

    Focus on actionable insights. Ignore routine informational messages like successful service starts, normal session handling, and periodic health checks.
    Be concise but thorough. Use markdown formatting."

        ${pkgs.jq}/bin/jq -n \
          --arg model "$MODEL" \
          --arg system "$SYSTEM_PROMPT" \
          --rawfile logs "$TMPDIR/deduped_logs.txt" \
          '{
            model: $model,
            messages: [
              {role: "system", content: $system},
              {role: "user", content: ("Here are the server logs to analyze:\n\n" + $logs)}
            ]
          }' > "$TMPDIR/request.json"

        ${pkgs.curl}/bin/curl -s \
          -H "Authorization: Bearer $API_KEY" \
          -H "Content-Type: application/json" \
          -d @"$TMPDIR/request.json" \
          "https://openrouter.ai/api/v1/chat/completions" > "$TMPDIR/response.json"

        RESPONSE=$(cat "$TMPDIR/response.json")

        ERROR=$(echo "$RESPONSE" | ${pkgs.jq}/bin/jq -r '.error.message // empty')
        if [ -n "$ERROR" ]; then
          echo "API Error: $ERROR"
          exit 1
        fi

        ANALYSIS=$(echo "$RESPONSE" | ${pkgs.jq}/bin/jq -r '.choices[0].message.content // empty')

        if [ -z "$ANALYSIS" ]; then
          echo "No analysis received from API"
          echo "Response: $RESPONSE"
          exit 1
        fi

        cat > "$REPORT_FILE" << EOF
    # Log Analysis Report - $(date +%Y-%m-%d)

    **Generated:** $(date -Iseconds)
    **Period:** Last $HOURS_BACK hours
    **Model:** $MODEL
    **Log lines analyzed:** $TOTAL_LINES

    ---

    $ANALYSIS
    EOF

        echo "Report written to $REPORT_FILE"

        ${optionalString cfg.ntfy.enable ''
          NTFY_TOPIC=$(cat "${cfg.ntfy.topicFile}")

          SUMMARY=$(echo "$ANALYSIS" | ${pkgs.gnugrep}/bin/grep -A5 "Health Summary" | head -6 || echo "$ANALYSIS" | head -5)

          HAS_CRITICAL=$(echo "$ANALYSIS" | ${pkgs.gnugrep}/bin/grep -qi "critical\|error\|fail" && echo "yes" || echo "no")

          if [ "$HAS_CRITICAL" = "yes" ]; then
            PRIORITY="high"
            TAGS="warning,server"
          else
            PRIORITY="default"
            TAGS="white_check_mark,server"
          fi

          ${pkgs.curl}/bin/curl -s \
            -H "Title: Log Analysis - $(date +%Y-%m-%d)" \
            -H "Priority: $PRIORITY" \
            -H "Tags: $TAGS" \
            -d "$SUMMARY" \
            "https://ntfy.sh/$NTFY_TOPIC"

          echo "Notification sent to ntfy"
        ''}

        echo "Done!"
  '';
in
{
  options.plusultra.services.log-analyzer = with types; {
    enable = mkEnableOption "log analyzer service";

    model = mkOption {
      type = str;
      default = "google/gemini-3-pro-preview";
      description = "OpenRouter model to use for analysis";
    };

    apiKeyFile = mkOption {
      type = path;
      default = config.age.secrets.openrouter-api.path;
      description = "Path to file containing OpenRouter API key";
    };

    hoursBack = mkOption {
      type = int;
      default = 24;
      description = "Number of hours of logs to analyze";
    };

    maxLines = mkOption {
      type = int;
      default = 4000;
      description = "Maximum number of log lines to send to LLM";
    };

    maxDuplicates = mkOption {
      type = int;
      default = 5;
      description = "Maximum occurrences of duplicate messages to keep";
    };

    priorityFilter = mkOption {
      type = nullOr str;
      default = null;
      example = "warning";
      description = "Only include logs at this priority level or higher (emerg, alert, crit, err, warning, notice, info, debug). If null, all priorities are included.";
    };

    extraFilterPatterns = mkOption {
      type = listOf str;
      default = [ ];
      example = [
        "some noisy pattern"
        "another pattern"
      ];
      description = "Additional grep patterns to filter out from logs";
    };

    outputDir = mkOption {
      type = str;
      default = "/var/log/log-analyzer";
      description = "Directory to store analysis reports";
    };

    ntfy = {
      enable = mkBoolOpt true "Send notifications via ntfy";

      topicFile = mkOption {
        type = path;
        default = config.age.secrets.ntfy-topic.path;
        description = "Path to file containing ntfy topic";
      };
    };

    schedule = {
      enable = mkBoolOpt false "Enable scheduled daily runs";

      time = mkOption {
        type = str;
        default = "06:00:00";
        description = "Time to run daily analysis (HH:MM:SS)";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.log-analyzer = {
      description = "Analyze system logs with LLM";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = analyzerScript;

        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        ProtectHostname = true;
        RestrictSUIDSGID = true;
        RestrictRealtime = true;
        LockPersonality = true;
        SystemCallArchitectures = "native";
      };
    };

    systemd.timers.log-analyzer = mkIf cfg.schedule.enable {
      description = "Daily log analysis timer";
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnCalendar = "*-*-* ${cfg.schedule.time}";
        Persistent = true;
        RandomizedDelaySec = "15min";
      };
    };
  };
}
