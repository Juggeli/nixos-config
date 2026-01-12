{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.services.todoist-poller;
  pollerScript = pkgs.writers.writePython3 "todoist-poller" {
    libraries = [ pkgs.python3Packages.requests ];
  } (builtins.readFile ./poller.py);
in
{
  options.plusultra.services.todoist-poller = with types; {
    enable = mkBoolOpt false "Whether to enable the Todoist completion poller.";
    interval = mkOption {
      type = str;
      default = "*:0/5";
      description = "Systemd OnCalendar interval (default: every 5 minutes)";
    };
    todoistApiKeyFile = mkOption {
      type = path;
      description = "Path to file containing Todoist API key";
    };
    lettaPasswordFile = mkOption {
      type = path;
      description = "Path to file containing Letta server password";
    };
    lettaBaseUrl = mkOption {
      type = str;
      default = "https://letta.jugi.cc";
      description = "Letta server base URL";
    };
    agentIdsFile = mkOption {
      type = path;
      description = "Path to file containing comma-separated Letta agent IDs";
    };
    stateDir = mkOption {
      type = str;
      default = "/var/lib/todoist-poller";
      description = "Directory to store sync token state";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.todoist-poller = {
      description = "Todoist completion poller for Letta";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pollerScript}";
        StateDirectory = "todoist-poller";
        Environment = [
          "TODOIST_API_KEY_FILE=${cfg.todoistApiKeyFile}"
          "LETTA_PASSWORD_FILE=${cfg.lettaPasswordFile}"
          "LETTA_BASE_URL=${cfg.lettaBaseUrl}"
          "AGENT_IDS_FILE=${cfg.agentIdsFile}"
          "STATE_DIR=${cfg.stateDir}"
        ];
      };
    };

    systemd.timers.todoist-poller = {
      description = "Timer for Todoist completion poller";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.interval;
        Persistent = true;
        RandomizedDelaySec = "30s";
      };
    };
  };
}
