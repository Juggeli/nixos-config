{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.cli-apps.yuki-memory;

  secondBrainPath = "/mnt/appdata/second-brain";

  isYukiSession = pkgs.writeShellScript "is-yuki-session" ''
    ${pkgs.jq}/bin/jq -e '.messages[0].info.agent == "yuki"' "$1" > /dev/null 2>&1
  '';

  getSessionCreatedDate = pkgs.writeShellScript "get-session-created-date" ''
    # Extract creation timestamp (ms) and convert to YYYY-MM-DD
    CREATED_MS=$(${pkgs.jq}/bin/jq -r '.info.time.created' "$1" 2>/dev/null)
    if [ -n "$CREATED_MS" ] && [ "$CREATED_MS" != "null" ]; then
      date -d "@$((CREATED_MS / 1000))" +%Y-%m-%d
    fi
  '';

  filterSessionJson = pkgs.writeShellScript "filter-session-json" ''
    ${pkgs.jq}/bin/jq -r '
      .messages[] | 
      select(.info.role == "user" or .info.role == "assistant") |
      "\(.info.role | ascii_upcase): " + (
        [.parts[] | select(.type == "text" and (.synthetic // false) == false) | .text] | join("\n")
      )
    ' "$1" | ${pkgs.gnused}/bin/sed '/^USER: $/d' | ${pkgs.gnused}/bin/sed '/^ASSISTANT: $/d'
  '';

  memoryScript = pkgs.writeShellScript "yuki-memory-extract" ''
        set -euo pipefail
        
        SECOND_BRAIN="${secondBrainPath}"
        TODAY=$(date +%Y-%m-%d)
        YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)
        YESTERDAY_LIST=$(date -d "yesterday" +"%-m/%-d/%Y")
        
        WORK_DIR=$(mktemp -d)
        trap "rm -rf $WORK_DIR" EXIT
        
        echo "=== Yuki Memory Extraction ==="
        echo "Date: $TODAY"
        echo "Processing sessions created on: $YESTERDAY"
        
        # Get session list, strip unicode chars
        ${pkgs.opencode}/bin/opencode session list 2>/dev/null | tail -n +3 | LC_ALL=C ${pkgs.gnused}/bin/sed 's/[^[:print:]]/ /g' > "$WORK_DIR/sessions.txt"
        
        # Get sessions that might be from yesterday:
        # 1. Sessions explicitly showing yesterday's date
        # 2. Sessions showing no date (today) - might have been created yesterday but updated after midnight
        # Lines with no date match: just have time like "5:23 PM" at end (no /20XX pattern)
        CANDIDATE_SESSIONS=$(grep -E "($YESTERDAY_LIST|[0-9]+:[0-9]+ [AP]M)$" "$WORK_DIR/sessions.txt" | ${pkgs.gawk}/bin/awk '{print $1}' || true)
        
        if [ -z "$CANDIDATE_SESSIONS" ]; then
          echo "No candidate sessions found"
          exit 0
        fi
        
        echo "Checking $(echo "$CANDIDATE_SESSIONS" | wc -w) candidate sessions..."
        
        # Export and filter each session (only yuki sessions created yesterday)
        TRANSCRIPT=""
        PROCESSED=0
        for SESSION_ID in $CANDIDATE_SESSIONS; do
          ${pkgs.opencode}/bin/opencode export "$SESSION_ID" > "$WORK_DIR/session.json" 2>/dev/null || continue
          
          # Check creation date (not update date)
          CREATED_DATE=$(${getSessionCreatedDate} "$WORK_DIR/session.json")
          if [ "$CREATED_DATE" != "$YESTERDAY" ]; then
            continue
          fi
          
          echo "Processing session: $SESSION_ID (created $CREATED_DATE)"
          
          # Skip non-yuki sessions
          if ! ${isYukiSession} "$WORK_DIR/session.json"; then
            echo "  Skipping: not a yuki session"
            continue
          fi
          
          SESSION_TEXT=$(${filterSessionJson} "$WORK_DIR/session.json" || true)
          if [ -n "$SESSION_TEXT" ]; then
            TRANSCRIPT="$TRANSCRIPT

    === Session: $SESSION_ID ===
    $SESSION_TEXT"
            ((PROCESSED++)) || true
          fi
        done
        
        echo "Found $PROCESSED yuki sessions from $YESTERDAY"
        
        if [ -z "$TRANSCRIPT" ]; then
          echo "No conversation content found"
          exit 0
        fi
        
        echo "Running memory extraction agent..."
        
        # Run the memory-extractor agent with the transcript
        ${pkgs.opencode}/bin/opencode run \
          --agent memory-extractor \
          "$SECOND_BRAIN" \
          "Process this conversation transcript from $YESTERDAY and update the memory files as needed.

    ## Conversation Transcript

    $TRANSCRIPT"
        
        echo "=== Memory extraction complete ==="
  '';

in
{
  options.plusultra.cli-apps.yuki-memory = with types; {
    enable = mkBoolOpt false "Whether or not to enable Yuki memory extraction service.";
  };

  config = mkIf cfg.enable {
    systemd.user.services.yuki-memory = {
      Unit = {
        Description = "Yuki memory extraction from OpenCode sessions";
        After = [ "network.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${memoryScript}";
        WorkingDirectory = "${secondBrainPath}";
        Environment = [
          "PATH=${
            lib.makeBinPath [
              pkgs.opencode
              pkgs.jq
              pkgs.gawk
              pkgs.coreutils
              pkgs.gnused
              pkgs.gnugrep
            ]
          }"
        ];
      };
    };

    systemd.user.timers.yuki-memory = {
      Unit = {
        Description = "Run Yuki memory extraction daily";
      };
      Timer = {
        OnCalendar = "*-*-* 03:00:00";
        Persistent = true;
      };
      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
  };
}
