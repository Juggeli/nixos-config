{ pkgs, ... }:
let
  downloaderBrr = pkgs.writeShellApplication {
    name = "downloaderBrr";
    runtimeInputs = [ pkgs.rclone ];
    text = ''
      SOURCE="''${1}"
      DEST="''${2}"

      rclone -v move "''${SOURCE}" "''${DEST}" --delete-empty-src-dirs
    '';
  };
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
    script = ''
      ${downloaderBrr}/bin/downloaderBrr ultra:downloads/done/private/ /tank/media/downloads/random/
      ${downloaderBrr}/bin/downloaderBrr ultra:downloads/done/public/ /tank/media/downloads/random/
      ${downloaderBrr}/bin/downloaderBrr ultra:downloads/done/radarr/ /tank/media/downloads/radarr/
      ${downloaderBrr}/bin/downloaderBrr ultra:downloads/done/radarr-anime/ /tank/media/downloads/radarr-anime/
      ${downloaderBrr}/bin/downloaderBrr ultra:downloads/done/sonarr/ /tank/media/downloads/sonarr/
      ${downloaderBrr}/bin/downloaderBrr ultra:downloads/done/sonarr-anime/ /tank/media/downloads/sonarr-anime/
    '';
  };
  systemd.timers.downloaderBrr = {
    wantedBy = [ "timers.target" ];
    partOf = [ "downloaderBrr.service" ];
    timerConfig = {
      OnUnitActiveSec = "30s";
      OnBootSec = "300s";
      Unit = "downloaderBrr.service";
    };
  };
}
