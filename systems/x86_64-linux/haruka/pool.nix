{ pkgs, ... }:
let
  mover = pkgs.writeShellApplication {
    name = "mover";
    runtimeInputs = [ pkgs.rsync ];
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
  downloader = pkgs.writeShellApplication {
    name = "downloader";
    runtimeInputs = [ pkgs.rclone ];
    text = ''
      SOURCE="''${1}"
      DEST="''${2}"
      TEMP="/mnt/pool/downloads/temp"

      rclone lsf --files-only -R "''${SOURCE}" > "''${DEST}/source_files.txt"

      while read -r file; do
        if ! grep -Fxq "''${file}" "''${DEST}/.downloaded_files.txt"; then
          if rclone copyto "''${SOURCE}/''${file}" "''${TEMP}/''${file}"; then
            mkdir -p "''$(dirname "''${DEST}/''${file}")"
            mv "''${TEMP}/''${file}" "''${DEST}/''${file}"
            echo "''${file}" >> "''${DEST}/.downloaded_files.txt"
            echo "Download success ''${file}"
          else
            echo "Download failed ''${file}"
          fi
        fi
      done < "''${DEST}/source_files.txt"
      rm "''${DEST}/source_files.txt"
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
    downloader
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

  systemd.services.snapraidSync = {
    description = "sync snapraid";
    serviceConfig = {
      User = "root";
      Type = "oneshot";
    };
    script = ''
      ${mover}/bin/mover /mnt/disks/cache/ /mnt/disks/slowpool/ 50
      ${pkgs.snapraid}/bin/snapraid --force-empty sync
    '';
  };
  systemd.timers.snapraidSync = {
    wantedBy = [ "timers.target" ];
    partOf = [ "snapraidSync.service" ];
    timerConfig = {
      OnCalendar = "*-*-* 12:00:00";
      Unit = "snapraidSync.service";
    };
  };
  systemd.services.snapraidScrub = {
    description = "scrub snapraid";
    serviceConfig = {
      User = "root";
      Type = "oneshot";
    };
    script = ''
      ${pkgs.snapraid}/bin/snapraid -p full scrub
    '';
  };
  systemd.timers.snapraidScrub = {
    wantedBy = [ "timers.target" ];
    partOf = [ "snapraidScrub.service" ];
    timerConfig = {
      OnCalendar = "*-*-01 12:00:00";
      Unit = "snapraidScrub.service";
    };
  };

  systemd.services.downloadStuff = {
    description = "download all stuff from server";
    serviceConfig = {
      User = "juggeli";
      Type = "oneshot";
    };
    script = ''
      ${downloader}/bin/downloader ultra.cc:downloads/qbittorrent/tv-sonarr-dl /mnt/pool/downloads/tv-sonarr-dl
      ${downloader}/bin/downloader ultra.cc:downloads/qbittorrent/done /mnt/pool/downloads/random
    '';
  };
  systemd.timers.downloadStuff = {
    wantedBy = [ "timers.target" ];
    partOf = [ "downloadStuff.service" ];
    timerConfig = {
      OnUnitActiveSec = "300s";
      OnBootSec = "300s";
      Unit = "downloadStuff.service";
    };
  };
}

