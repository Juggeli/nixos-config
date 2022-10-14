{ config, pkgs, ... }:
let
  # mover = pkgs.writeTextFile {
  #   name = "mover";
  #   destination = "/bin/mover";
  #   executable = true;
  #
  #   text = ''
  #     #!/bin/sh
  #
  #     if [ $# != 3 ]; then
  #       echo "usage: $0 <cache-drive> <backing-pool> <percentage>"
  #       exit 1
  #     fi
  #
  #     CACHE="${1}"
  #     BACKING="${2}"
  #     PERCENTAGE=${3}
  #
  #     set -o errexit
  #     while [ $(df --output=pcent "${CACHE}" | grep -v Use | cut -d'%' -f1) -gt ${PERCENTAGE} ]
  #     do
  #       FILE=$(find "${CACHE}" -type f -printf '%A@ %P\n' | \
  #             sort | \
  #             head -n 1 | \
  #             cut -d' ' -f2-)
  #       test -n "${FILE}"
  #       rsync -axqHAXWESR --preallocate --remove-source-files "${CACHE}/./${FILE}" "${BACKING}/"
  #       done
  #   '';
  # };
in {
  environment.systemPackages = with pkgs; [
    cryptsetup
    fuse3 # for nofail option on mergerfs (fuse defaults to fuse2)
    mergerfs
    mergerfs-tools
    snapraid
  ];

  environment.etc.crypttab.text = ''
    disk1 UUID=06be6db9-b208-4c7a-a276-acf0b1dc4aff /pool.key nofail,timeout=5m
    disk2 UUID=16797d20-6514-45a1-8c93-6cb5545469ef /pool.key nofail,timeout=5m
    disk3 UUID=62eb66ea-9239-4784-8d33-7a1ba4d4faa0 /pool.key nofail,timeout=5m
    parity UUID=62e6dad0-7f95-45ff-adaf-598a75ffcb40 /pool.key nofail,timeout=5m
  '';

  fileSystems = {
    "/mnt/disk1" = {
      device = "/dev/mapper/disk1";
      fsType = "btrfs";
      options =
        [ "defaults" "noatime" "compress-force=zstd" "nofail" "autodefrag" ];
    };

    "/mnt/disk2" = {
      device = "/dev/mapper/disk2";
      fsType = "btrfs";
      options =
        [ "defaults" "noatime" "compress-force=zstd" "nofail" "autodefrag" ];
    };

    "/mnt/disk3" = {
      device = "/dev/mapper/disk3";
      fsType = "btrfs";
      options =
        [ "defaults" "noatime" "compress-force=zstd" "nofail" "autodefrag" ];
    };

    "/mnt/parity" = {
      device = "/dev/mapper/parity";
      fsType = "btrfs";
      options =
        [ "defaults" "noatime" "compress-force=zstd" "nofail" "autodefrag" ];
    };

    "/mnt/slowpool" = {
      device = "/mnt/disk1:/mnt/disk2:/mnt/disk3";
      fsType = "fuse.mergerfs";
      options = [
        "defaults"
        "allow_other"
        "use_ino"
        "cache.files=partial"
        "dropcacheonclose=true"
        "category.create=epmfs"
        "moveonenospc=true"
        "minfreespace=400G"
      ];
    };

    "/mnt/pool" = {
      device = "/mnt/cache:/mnt/disk1:/mnt/disk2:/mnt/disk3";
      fsType = "fuse.mergerfs";
      options = [
        "defaults"
        "allow_other"
        "use_ino"
        "cache.files=partial"
        "dropcacheonclose=true"
        "category.create=epmfs"
        "moveonenospc=true"
      ];
    };
  };

  # btrfs: enable autoscrub
  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [ "/mnt/cache" "/mnt/disk1" "/mnt/disk2" "/mnt/disk3" "/mnt/parity" ];
  };

  environment.etc."snapraid.conf".text = ''
    parity /mnt/parity/.snapraid.parity

    content /mnt/parity/snapraid.content
    content /mnt/cache/.snapraid.content

    data cache /mnt/cache
    data disk1 /mnt/disk1
    data disk2 /mnt/disk2
    data disk3 /mnt/disk3
  '';

  systemd.services.snapraidMaintenance = {
    description = "sync and scrub snapraid";
    serviceConfig = {
      User = "juggeli";
      Type = "oneshot";
    };
    script = ''
      ${pkgs.snapraid}/bin/snapraid sync
      ${pkgs.snapraid}/bin/snapraid scrub
      '';
  };
  systemd.timers.snapraidMaintenance = {
    wantedBy = [ "timers.target" ];
    partOf = [ "snapraidMaintenance.service" ];
    timerConfig = {
      OnCalendar = "*-*-* 6:00:00";
      Unit = "snapraidMaintenance.service";
    };
  };
}
