{ config, lib, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.filesystem.btrfs;
in
{
  options.plusultra.filesystem.btrfs = with types; {
    enable = mkOption {
      default = false;
      type = with types; bool;
      description = "Enables settings for a BTRFS installation including snapshots";
    };
    autoscrub = mkOption {
      default = true;
      type = with types; bool;
      description = "Enable autoscrubbing of file systems";
    };
  };

  config = mkIf cfg.enable {
    boot = {
      supportedFilesystems = [
        "btrfs"
      ];
    };

    # fileSystems = {
    #   "/".options = [ "subvol=root" "compress=zstd" "noatime" ];
    #   "/home".options = [ "subvol=home/active" "compress=zstd" "noatime" ];
    #   "/home/.snapshots".options = [ "subvol=home/snapshots" "compress=zstd" "noatime" ];
    #   "/nix".options = [ "subvol=nix" "compress=zstd" "noatime" ];
    #   "/var/log".options = [ "subvol=var_log" "compress=zstd" "noatime" ];
    #   "/var/log".neededForBoot = true;
    # };

    services = {
      btrbk = {
        instances."btrbak" = {
          onCalendar = "*-*-* *:00:00";
          settings = {
            timestamp_format = "long";
            preserve_day_of_week = "sunday";
            preserve_hour_of_day = "0";
            snapshot_preserve = "48h 10d 4w 12m 10y";
            snapshot_preserve_min = "2d";
            volume."/persist-home" = {
              snapshot_create = "always";
              subvolume = ".";
              snapshot_dir = ".snapshots";
            };
            volume."/persist" = {
              snapshot_create = "always";
              subvolume = ".";
              snapshot_dir = ".snapshots";
            };
          };
        };
      };
      btrfs.autoScrub = mkIf cfg.autoscrub {
        enable = true;
        fileSystems = [ "/" ];
      };
    };
  };
}
