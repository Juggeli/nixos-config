{
  flake.nixosModules.zfs = {
    boot.supportedFilesystems = [ "zfs" ];
    boot.zfs.forceImportRoot = false;

    services.zfs = {
      autoScrub.enable = true;
      trim.enable = true;
      autoSnapshot = {
        enable = true;
        flags = "-k -p --utc";
        frequent = 4;
        hourly = 24;
        daily = 14;
        weekly = 4;
        monthly = 0;
      };
    };
  };
}
