{ pkgs, lib, ... }:
let
  downloaderBrr = pkgs.writeShellApplication {
    name = "downloaderBrr";
    runtimeInputs = [ pkgs.rclone ];
    text = ''
      set -euo pipefail
      
      if [ $# -ne 2 ]; then
        echo "Usage: $0 <source> <destination>"
        exit 1
      fi
      
      SOURCE="''${1}"
      DEST="''${2}"
      
      if [ ! -d "''${DEST}" ]; then
        echo "Error: Destination directory ''${DEST} does not exist"
        exit 1
      fi

      echo "Moving from ''${SOURCE} to ''${DEST}"
      rclone -v move "''${SOURCE}" "''${DEST}" --delete-empty-src-dirs
    '';
  };
  
  downloadMappings = [
    { src = "ultra:downloads/done/private/"; dest = "/tank/media/downloads/random/"; }
    { src = "ultra:downloads/done/public/"; dest = "/tank/media/downloads/random/"; }
    { src = "ultra:downloads/done/radarr/"; dest = "/tank/media/downloads/radarr/"; }
    { src = "ultra:downloads/done/radarr-anime/"; dest = "/tank/media/downloads/radarr-anime/"; }
    { src = "ultra:downloads/done/sonarr/"; dest = "/tank/media/downloads/sonarr/"; }
    { src = "ultra:downloads/done/sonarr-anime/"; dest = "/tank/media/downloads/sonarr-anime/"; }
  ];
in
{
  environment.systemPackages = with pkgs; [
    btrfs-progs
    cryptsetup
    hdparm
  ];

  powerManagement.powerUpCommands = with pkgs; ''
    for dev in /dev/sd[a-z]; do
      if [ -b "$dev" ]; then
        ${hdparm}/bin/hdparm -S 242 -B 127 "$dev" || true
      fi
    done
  '';

  systemd.services.downloaderBrr = {
    description = "download all stuff from brr";
    serviceConfig = {
      User = "juggeli";
      Type = "oneshot";
    };
    script = lib.concatMapStringsSep "\n" 
      (mapping: "${downloaderBrr}/bin/downloaderBrr ${mapping.src} ${mapping.dest}") 
      downloadMappings;
  };
  systemd.timers.downloaderBrr = {
    wantedBy = [ "timers.target" ];
    partOf = [ "downloaderBrr.service" ];
    timerConfig = {
      OnUnitActiveSec = "1m";
      OnBootSec = "300s";
      Unit = "downloaderBrr.service";
    };
  };
}
