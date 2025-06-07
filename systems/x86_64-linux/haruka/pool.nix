{
  pkgs,
  lib,
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
      {
        src = "ultra:downloads/done/radarr/";
        dest = "/tank/media/downloads/radarr/";
      }
      {
        src = "ultra:downloads/done/radarr-anime/";
        dest = "/tank/media/downloads/radarr-anime/";
      }
      {
        src = "ultra:downloads/done/sonarr/";
        dest = "/tank/media/downloads/sonarr/";
      }
      {
        src = "ultra:downloads/done/sonarr-anime/";
        dest = "/tank/media/downloads/sonarr-anime/";
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
