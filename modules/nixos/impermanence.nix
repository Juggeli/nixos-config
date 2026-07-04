{
  flake.nixosModules.impermanence =
    { pkgs, ... }:
    let
      pool = "rpool";
      rootDataset = "nixos/root";

      impermanence-fsdiff = pkgs.writeShellScriptBin "impermanence-fsdiff" ''
        set -euo pipefail

        echo "Comparing current root with @blank snapshot..."
        echo "Files that have been created or modified:"
        echo ""

        ${pkgs.zfs}/bin/zfs diff "${pool}/${rootDataset}@blank" "${pool}/${rootDataset}" | \
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

      zfs-clean-snapshots = pkgs.writeShellScriptBin "zfs-clean-snapshots" ''
        set -euo pipefail

        BLANK_SNAP="${pool}/${rootDataset}@blank"

        echo "Finding snapshots to delete (preserving $BLANK_SNAP)..."

        SNAPSHOTS=$(${pkgs.zfs}/bin/zfs list -H -t snapshot -o name | grep -v "^$BLANK_SNAP$" || true)

        if [ -z "$SNAPSHOTS" ]; then
          echo "No snapshots to delete."
          exit 0
        fi

        echo "Will delete:"
        echo "$SNAPSHOTS"
        echo ""
        read -p "Proceed? [y/N] " -n 1 -r
        echo

        if [[ $REPLY =~ ^[Yy]$ ]]; then
          echo "$SNAPSHOTS" | while read -r snap; do
            echo "Destroying $snap..."
            ${pkgs.zfs}/bin/zfs destroy "$snap"
          done
          echo "Done."
        else
          echo "Aborted."
        fi
      '';
    in
    {
      boot.initrd.systemd = {
        enable = true;
        services.rollback-root = {
          description = "Rollback ZFS root dataset to a pristine state";
          wantedBy = [ "initrd.target" ];
          after = [ "zfs-import-${pool}.service" ];
          before = [ "sysroot.mount" ];
          path = [ pkgs.zfs ];
          unitConfig.DefaultDependencies = "no";
          serviceConfig.Type = "oneshot";
          script = ''
            zfs rollback -r ${pool}/${rootDataset}@blank
          '';
        };
      };

      environment.systemPackages = [
        pkgs.zfs
        impermanence-fsdiff
        zfs-clean-snapshots
      ];

      environment.persistence."/persist" = {
        hideMounts = true;
        directories = [
          "/var/lib/bluetooth"
          "/var/lib/nixos"
          "/var/lib/systemd/coredump"
          "/var/lib/NetworkManager/"
        ];
      };

      fileSystems = {
        "/persist".neededForBoot = true;
        "/persist-home".neededForBoot = true;
        "/nix".neededForBoot = true;
      };

      programs.fuse.userAllowOther = true;
    };
}
