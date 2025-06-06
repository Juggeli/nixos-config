{ pkgs, lib, config, ... }:
let
  downloaderBrr = pkgs.writeShellApplication {
    name = "downloaderBrr";
    runtimeInputs = [ pkgs.rsync pkgs.findutils ];
    text = ''
      set -euo pipefail
      
      if [ $# -ne 2 ]; then
        echo "Usage: $0 <source> <destination>"
        exit 1
      fi
      
      SOURCE="''${1}"
      DEST="''${2}"
      
      if [ ! -d "''${SOURCE}" ]; then
        echo "Source directory ''${SOURCE} does not exist, skipping"
        exit 0
      fi
      
      if [ ! -d "''${DEST}" ]; then
        echo "Error: Destination directory ''${DEST} does not exist"
        exit 1
      fi

      if [ "$(find "''${SOURCE}" -type f | wc -l)" -eq 0 ]; then
        echo "No files in ''${SOURCE}, skipping"
        exit 0
      fi

      echo "Moving files from ''${SOURCE} to ''${DEST}"
      rsync -av --remove-source-files "''${SOURCE}"/ "''${DEST}"/
      find "''${SOURCE}" -type d -empty -delete || true
    '';
  };
  
  downloadMappings = [
    { src = "/mnt/remote-downloads/private/"; dest = "/tank/media/downloads/random/"; }
    { src = "/mnt/remote-downloads/public/"; dest = "/tank/media/downloads/random/"; }
    { src = "/mnt/remote-downloads/radarr/"; dest = "/tank/media/downloads/radarr/"; }
    { src = "/mnt/remote-downloads/radarr-anime/"; dest = "/tank/media/downloads/radarr-anime/"; }
    { src = "/mnt/remote-downloads/sonarr/"; dest = "/tank/media/downloads/sonarr/"; }
    { src = "/mnt/remote-downloads/sonarr-anime/"; dest = "/tank/media/downloads/sonarr-anime/"; }
  ];
in
{
  environment.systemPackages = with pkgs; [
    btrfs-progs
    cryptsetup
    hdparm
    rclone
  ];

  systemd.tmpfiles.rules = [
    "d /mnt/remote-downloads 0755 juggeli users -"
  ];

  users.users.juggeli.extraGroups = [ "fuse" ];

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
  systemd.services.rclone-mount = {
    description = "Mount rclone remote downloads";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    requires = [ "network-online.target" ];
    serviceConfig = {
      Type = "notify";
      ExecStart = "${pkgs.rclone}/bin/rclone mount ultra:downloads/done /mnt/remote-downloads --vfs-cache-mode writes --allow-other --poll-interval 15s --config ${config.users.users.juggeli.home}/.config/rclone/rclone.conf";
      ExecStop = "${pkgs.fuse}/bin/fusermount -u /mnt/remote-downloads";
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };

  systemd.timers.downloaderBrr = {
    wantedBy = [ "timers.target" ];
    partOf = [ "downloaderBrr.service" ];
    after = [ "rclone-mount.service" ];
    timerConfig = {
      OnUnitActiveSec = "30s";
      OnBootSec = "60s";
      Unit = "downloaderBrr.service";
    };
  };

  system.fsPackages = [ pkgs.rclone ];
}
