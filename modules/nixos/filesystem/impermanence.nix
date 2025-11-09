{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg_impermanence = config.plusultra.filesystem.impermanence;
  cfg_encrypt = config.plusultra.filesystem.encryption;
  # Running this will show what changed during boot to potentially use for persisting
  impermanence-fsdiff = pkgs.writeShellScriptBin "impermanence-fsdiff" ''
    _mount_drive=''${1:-"$(mount | grep '.* on / type btrfs' | awk '{ print $1}')"}
    _tmp_root=$(mktemp -d)
    mkdir -p "$_tmp_root"
    doas mount -o subvol=/ "$_mount_drive" "$_tmp_root" > /dev/null 2>&1

    set -euo pipefail

    OLD_TRANSID=$(doas btrfs subvolume find-new $_tmp_root/root-blank 9999999)
    OLD_TRANSID=''${OLD_TRANSID#transid marker was }

    doas btrfs subvolume find-new "$_tmp_root/${cfg_impermanence.root-subvol}" "$OLD_TRANSID" | sed '$d' | cut -f17- -d' ' | sort | uniq |
    while read path; do
      path="/$path"
       if [ -L "$path" ]; then
          : # The path is a symbolic link, so is probably handled by NixOS already
        elif [ -d "$path" ]; then
          : # The path is a directory, ignore
        else
          echo "$path"
        fi
    done
    doas umount "$_tmp_root"
    rm -rf "$_tmp_root"
  '';
in
{
  options.plusultra.filesystem.impermanence = with types; {
    enable = mkBoolOpt false "Whether or not to enable impermanance.";
    root-subvol = mkOption {
      type = types.str;
      default = "root";
      description = "Root subvolume to wipe on boot";
    };
    blank-root-subvol = mkOption {
      type = types.str;
      default = "root-blank";
      description = "Blank root subvolume to restore on boot";
    };
    directories = mkOption {
      type = types.listOf types.anything;
      default = [ ];
      description = "Directories that should be persisted between reboots";
    };
    files = mkOption {
      type = types.listOf types.anything;
      default = [ ];
      description = "Files that should be persisted between reboots";
    };
  };

  config = lib.mkMerge [
    {
      boot.initrd = lib.mkMerge [
        (lib.mkIf (cfg_impermanence.enable && !cfg_encrypt.enable) {
          postDeviceCommands = pkgs.lib.mkBefore ''
            mkdir -p /mnt
            mount -o subvol=/ /dev/disk/by-partlabel/rootfs /mnt
            btrfs subvolume list -o /mnt/${cfg_impermanence.root-subvol} | cut -f9 -d' ' |
            while read subvolume; do
                echo "Deleting /$subvolume subvolume"
                btrfs subvolume delete "/mnt/$subvolume"
            done &&
            echo "Deleting /${cfg_impermanence.root-subvol} subvolume" &&
            btrfs subvolume delete /mnt/${cfg_impermanence.root-subvol}
            echo "Restoring blank /${cfg_impermanence.root-subvol} subvolume"
            btrfs subvolume snapshot /mnt/${cfg_impermanence.blank-root-subvol} /mnt/${cfg_impermanence.root-subvol}
            mkdir -p /mnt/${cfg_impermanence.root-subvol}/mnt
            umount /mnt
          '';
        })

        (lib.mkIf (cfg_impermanence.enable && cfg_encrypt.enable) {
          systemd = {
            enable = true;
            services.rollback = {
              description = "Rollback BTRFS root subvolume to a pristine state";
              wantedBy = [
                "initrd.target"
              ];
              after = [
                "systemd-cryptsetup@${cfg_encrypt.encrypted-partition}.service"
              ];
              before = [
                "sysroot.mount"
              ];
              unitConfig.DefaultDependencies = "no";
              serviceConfig.Type = "oneshot";
              script = ''
                mkdir -p /mnt
                mount -o subvol=/ /dev/mapper/${cfg_encrypt.encrypted-partition} /mnt
                btrfs subvolume list -o /mnt/${cfg_impermanence.root-subvol} | cut -f9 -d' ' |
                while read subvolume; do
                  echo "Deleting /$subvolume subvolume"
                  btrfs subvolume delete "/mnt/$subvolume"
                done &&
                echo "Deleting /${cfg_impermanence.root-subvol} subvolume" &&
                btrfs subvolume delete /mnt/${cfg_impermanence.root-subvol}
                echo "Restoring blank /${cfg_impermanence.root-subvol} subvolume"
                btrfs subvolume snapshot /mnt/${cfg_impermanence.blank-root-subvol} /mnt/${cfg_impermanence.root-subvol}
                mkdir -p /mnt/${cfg_impermanence.root-subvol}/mnt
                umount /mnt
              '';
            };
          };
        })
      ];

      environment = mkIf cfg_impermanence.enable {
        systemPackages = [
          impermanence-fsdiff
        ];

        persistence."/persist" = {
          hideMounts = true;
          directories = [
            "/var/lib/bluetooth"
            "/var/lib/nixos"
            "/var/lib/systemd/coredump"
            "/var/lib/NetworkManager/"
          ]
          ++ cfg_impermanence.directories;
          files = [
          ]
          ++ cfg_impermanence.files;
        };
      };

      fileSystems = mkIf cfg_impermanence.enable {
        "/persist" = {
          neededForBoot = true;
        };
        "/persist-home" = {
          neededForBoot = true;
        };
        "/etc/ssh" = {
          neededForBoot = true;
        };
        "/nix" = {
          neededForBoot = true;
        };
      };

      programs.fuse.userAllowOther = true;
    }
  ];
}
