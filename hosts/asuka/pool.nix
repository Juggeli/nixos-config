{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    cryptsetup
    fuse3 # for nofail option on mergerfs (fuse defaults to fuse2)
    mergerfs
    mergerfs-tools
    snapraid
  ];

  boot.initrd.luks.devices = {
    disk1.device = "/dev/disk/by-uuid/06be6db9-b208-4c7a-a276-acf0b1dc4aff";
    disk2.device = "/dev/disk/by-uuid/16797d20-6514-45a1-8c93-6cb5545469ef";
    disk3.device = "/dev/disk/by-uuid/62eb66ea-9239-4784-8d33-7a1ba4d4faa0";
    # parity.device = "/dev/disk/by-uuid/";
  };

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

    # "/mnt/parity" = {
    #   device = "/dev/mapper/parity";
    #   fsType = "btrfs";
    #   options =
    #     [ "defaults" "noatime" "compress-force=zstd" "nofail" "autodefrag" ];
    # };

    # mergerfs: merge drives
    "/mnt/pool" = {
      device = "/mnt/disk1:/mnt/disk2:/mnt/disk3";
      fsType = "fuse.mergerfs";
      options = [
        "defaults"
        "allow_other"
        "use_ino"
        "cache.files=partial"
        "dropcacheonclose=true"
        "category.create=epmfs"
        "nofail"
      ];
    };
  };

  # btrfs: enable autoscrub
  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [ "/mnt/disk1" "/mnt/disk2" "/mnt/disk3" "/mnt/parity" ];
  };

  # environment.etc."snapraid.conf".text = ''
  #   parity /mnt/manager/.snapraid.parity
  #
  #   content /mnt/manager/snapraid.content
  #   content /mnt/shizuka/.snapraid.content
  #
  #   data shizuka /mnt/shizuka
  #   data sui /mnt/sui
  #   data sumire /mnt/sumire
  # '';

  # systemd.services = {
  #   sishSnapraidMaintenance = {
  #     description = "sync and scrub sish snapraid";
  #     serviceConfig = {
  #       User = "fc";
  #       Type = "oneshot";
  #     };
  #     script = ''
  #       ${pkgs.snapraid}/bin/snapraid sync
  #       ${pkgs.snapraid}/bin/snapraid scrub
  #     '';
  #   };
  # };
}
