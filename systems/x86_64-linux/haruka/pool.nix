{ pkgs, ... }:
let
  downloaderBrr = pkgs.writeShellApplication {
    name = "downloaderBrr";
    runtimeInputs = [ pkgs.rclone ];
    text = ''
      SOURCE="''${1}"
      DEST="''${2}"

      rclone -v move "''${SOURCE}" "''${DEST}"
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
    ${hdparm}/bin/hdparm -S 241 -B 127 /dev/sda
    ${hdparm}/bin/hdparm -S 241 -B 127 /dev/sdb
    ${hdparm}/bin/hdparm -S 241 -B 127 /dev/sdc
    ${hdparm}/bin/hdparm -S 241 -B 127 /dev/sdd
    ${hdparm}/bin/hdparm -S 241 -B 127 /dev/sde
    ${hdparm}/bin/hdparm -S 241 -B 127 /dev/sdf
  '';

  systemd.services.downloaderBrr = {
    description = "download all stuff from brr";
    serviceConfig = {
      User = "juggeli";
      Type = "oneshot";
    };
    script = ''
      ${downloaderBrr}/bin/downloaderBrr brr:/mnt/pool/done/Private/ /tank/downloads/random/
      ${downloaderBrr}/bin/downloaderBrr brr:/mnt/pool/done/Public/ /tank/downloads/random/
      ${downloaderBrr}/bin/downloaderBrr brr:/mnt/pool/done/radarr/ /tank/downloads/radarr/
      ${downloaderBrr}/bin/downloaderBrr brr:/mnt/pool/done/radarr-anime/ /tank/downloads/radarr-anime/
      ${downloaderBrr}/bin/downloaderBrr brr:/mnt/pool/done/sonarr/ /tank/downloads/sonarr/
      ${downloaderBrr}/bin/downloaderBrr brr:/mnt/pool/done/sonarr-anime/ /tank/downloads/sonarr-anime/
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
