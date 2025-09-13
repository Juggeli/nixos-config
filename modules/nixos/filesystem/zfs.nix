{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.filesystem.zfs;
in
{
  options.plusultra.filesystem.zfs = with types; {
    enable = mkOption {
      default = false;
      type = with types; bool;
      description = "Enables support for non root ZFS filesystems";
    };
    autoscrub = mkOption {
      default = true;
      type = with types; bool;
      description = "Enable autoscrubbing of file systems";
    };
    autotrim = mkOption {
      default = true;
      type = with types; bool;
      description = "Enable autotrim of file systems";
    };
    zed = mkOption {
      default = true;
      type = with types; bool;
      description = "Enable zed support to send notifications to ntfy";
    };
    autoSnapshot = mkOption {
      default = true;
      type = with types; bool;
      description = "Enable automatic ZFS snapshots";
    };
  };

  config = mkIf cfg.enable {
    boot = {
      supportedFilesystems = [
        "zfs"
      ];
      zfs.forceImportRoot = false;
    };

    services.zfs = {
      autoScrub = mkIf cfg.autoscrub { enable = true; };
      trim = mkIf cfg.autotrim { enable = true; };
      autoSnapshot = mkIf cfg.autoSnapshot {
        enable = true;
        flags = "-k -p --utc";
        frequent = 4;
        hourly = 48;
        daily = 30;
        weekly = 12;
        monthly = 0;
      };
      zed = mkIf cfg.zed {
        settings = {
          ZED_DEBUG_LOG = "/tmp/zed.debug.log";
          ZED_NOTIFY_INTERVAL_SECS = 3600;
          ZED_NOTIFY_VERBOSE = true;
          ZED_SCRUB_AFTER_RESILVER = true;
          ZED_NTFY_TOPIC = "@ntfy-topic@";
        };
      };
    };

    system.activationScripts."ntfy-topic" = ''
      configFile=/etc/zfs/zed.d/zed.rc
      secret=$(cat "${config.age.secrets.ntfy-topic.path}")
      ${pkgs.gnused}/bin/sed -i "s#@ntfy-topic@#$secret#" "$configFile"
    '';
  };
}
