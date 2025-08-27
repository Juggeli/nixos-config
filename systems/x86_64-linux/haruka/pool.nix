{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    btrfs-progs
    cryptsetup
    hdparm
    rclone
  ];

  powerManagement.powerUpCommands = with pkgs; ''
    for dev in /dev/sd[a-z]; do
      if [ -b "$dev" ]; then
        ${hdparm}/bin/hdparm -S 242 -B 127 "$dev" || true
      fi
    done
  '';

  plusultra.services.remote-downloader = {
    enable = true;
    mappings = [
      {
        src = "ultra:downloads/done/private/";
        dest = "/tank/media/downloads/random/";
      }
      {
        src = "ultra:downloads/done/public/";
        dest = "/tank/media/downloads/random/";
      }
    ];
    webhook = {
      enable = true;
      port = 8081;
    };
    timer = {
      interval = "5m";
    };
  };

  system.fsPackages = [ pkgs.rclone ];
}
