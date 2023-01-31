{ config, pkgs, ... }:
let
  mover = pkgs.writeShellApplication {
    name = "mover";
    runtimeInputs = [pkgs.rsync];
    text = ''
if [ $# != 3 ]; then
  echo "usage: $0 <cache-drive> <backing-pool> <percentage>"
  exit 1
fi

CACHE="''${1}"
BACKING="''${2}"
PERCENTAGE=''${3}

set -o errexit
# shellcheck disable=SC2046,SC2086
while [ $(df --output=pcent "''${CACHE}" | grep -v Use | cut -d'%' -f1) -gt ''${PERCENTAGE} ]
do
    set +o pipefail
    FILE=$(find "''${CACHE}" -type f -not -iname "*.!qB" -not -iname ".snapraid.content" -printf '%A@ %P\n' | \
                  sort | \
                  head -n 1 | \
                  cut -d' ' -f2-)
    echo ''${FILE}
    test -n "''${FILE}"
    rsync -axqHAXWESR --preallocate --remove-source-files "''${CACHE}/./''${FILE}" "''${BACKING}/"
done
    '';
  };
in
{
  environment.systemPackages = with pkgs; [
    btrfs-progs
    cryptsetup
    fuse3 # for nofail option on mergerfs (fuse defaults to fuse2)
    mergerfs
    mergerfs-tools
    snapraid
    python3 # to run mover script
    hdparm
    mover
  ];

  # /etc/crypttab: decrypt drives
  # NOTE: keys need to be copied over manually
  environment.etc.crypttab.text = ''
    cache UUID=1c8eb125-e784-4ca2-b713-80a87fd65332 /pool.key nofail,timeout=5m
    disk1 UUID=b2fae3e5-97e0-425b-aa55-000eead6465e /pool.key nofail,timeout=5m
    disk2 UUID=62eb66ea-9239-4784-8d33-7a1ba4d4faa0 /pool.key nofail,timeout=5m
    parity UUID=7064f0ca-116c-4ef8-af27-53f38552a492 /pool.key nofail,timeout=5m
  '';

  powerManagement.powerUpCommands = with pkgs;''
    ${hdparm}/bin/hdparm -S 241 -B 127 /dev/sda
    ${hdparm}/bin/hdparm -S 241 -B 127 /dev/sdb
    ${hdparm}/bin/hdparm -S 241 -B 127 /dev/sdc
  '';
  
  fileSystems = {
    "/mnt/disks/disk1" = {
      device = "/dev/mapper/disk1";
      fsType = "btrfs";
      options =
        [ "defaults" "compress-force=zstd" "nofail" "autodefrag" ];
    };

    "/mnt/disks/disk2" = {
      device = "/dev/mapper/disk2";
      fsType = "btrfs";
      options =
        [ "defaults" "compress-force=zstd" "nofail" "autodefrag" ];
    };

    "/mnt/disks/cache" = {
      device = "/dev/mapper/cache";
      fsType = "btrfs";
      options =
        [ "defaults" "compress-force=zstd" "nofail" "autodefrag" ];
    };

    "/mnt/disks/parity" = {
      device = "/dev/mapper/parity";
      fsType = "xfs";
    };

    "/mnt/disks/slowpool" = {
      device = "/mnt/disks/disk1:/mnt/disks/disk2";
      fsType = "fuse.mergerfs";
      options = [
        "defaults"
        "allow_other"
        "use_ino"
        "cache.files=partial"
        "dropcacheonclose=true"
        "category.create=epff"
        "moveonenospc=true"
      ];
    };

    "/mnt/pool" = {
      device = "/mnt/disks/cache:/mnt/disks/disk1:/mnt/disks/disk2";
      fsType = "fuse.mergerfs";
      options = [
        "defaults"
        "allow_other"
        "use_ino"
        "cache.files=partial"
        "dropcacheonclose=true"
        "category.create=ff"
        "moveonenospc=true"
      ];
    };
  };

  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [ "/mnt/disks/cache" "/mnt/disks/disk1" "/mnt/disks/disk2" ];
  };

  environment.etc."snapraid.conf".text = ''
    parity /mnt/disks/parity/.snapraid.parity

    content /mnt/disks/parity/snapraid.content
    content /mnt/disks/cache/.snapraid.content

    data cache /mnt/disks/cache
    data disk1 /mnt/disks/disk1
    data disk2 /mnt/disks/disk2

    exclude *.log
    exclude *.!qB
  '';

  # systemd.services.snapraidMaintenance = {
  #   description = "sync and scrub snapraid";
  #   serviceConfig = {
  #     User = "root";
  #     Type = "oneshot";
  #   };
  #   script = ''
  #     ${pkgs.snapraid}/bin/snapraid sync
  #     ${pkgs.snapraid}/bin/snapraid scrub
  #   '';
  # };
  # systemd.timers.snapraidMaintenance = {
  #   wantedBy = [ "timers.target" ];
  #   partOf = [ "snapraidMaintenance.service" ];
  #   timerConfig = {
  #     OnCalendar = "*-*-* 6:00:00";
  #     Unit = "snapraidMaintenance.service";
  #   };
  # };
}

