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
  impermanence-fsdiff = pkgs.writeShellScriptBin "impermanence-fsdiff" ''
    set -euo pipefail

    POOL="${cfg_impermanence.pool}"
    DATASET="${cfg_impermanence.root-dataset}"

    echo "Comparing current root with @blank snapshot..."
    echo "Files that have been created or modified:"
    echo ""

    ${pkgs.zfs}/bin/zfs diff "$POOL/$DATASET@blank" "$POOL/$DATASET" | \
      grep -E '^M\s+/|^\+\s+/' | \
      awk '{print $2}' | \
      while read -r path; do
        if [ -L "$path" ]; then
          : # Symlink, managed by NixOS
        elif [ -d "$path" ]; then
          : # Directory, ignore
        else
          echo "$path"
        fi
      done
  '';
in
{
  options.plusultra.filesystem.impermanence = with types; {
    enable = mkBoolOpt false "Whether or not to enable impermanance.";
    pool = mkOption {
      type = types.str;
      default = "rpool";
      description = "ZFS pool name";
    };
    root-dataset = mkOption {
      type = types.str;
      default = "nixos/root";
      description = "Root dataset path";
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

  config = lib.mkIf cfg_impermanence.enable {
    boot.initrd.systemd = {
      enable = true;
      services.rollback-root = {
        description = "Rollback ZFS root dataset to a pristine state";
        wantedBy = [ "initrd.target" ];
        after =
          (lib.optionals cfg_encrypt.enable [
            "systemd-cryptsetup@${cfg_encrypt.encrypted-partition}.service"
          ])
          ++ [
            "zfs-import-${cfg_impermanence.pool}.service"
          ];
        before = [ "sysroot.mount" ];
        unitConfig.DefaultDependencies = "no";
        serviceConfig.Type = "oneshot";
        script = ''
          zfs rollback -r ${cfg_impermanence.pool}/${cfg_impermanence.root-dataset}@blank
        '';
      };
    };

    environment = {
      systemPackages = [
        pkgs.zfs
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
        files = [ ] ++ cfg_impermanence.files;
      };
    };

    fileSystems = {
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
  };
}
