{ config, pkgs, ... }:
{
  imports = [
    ./hardware.nix
    ./disk.nix
    ./autologin.nix
    ./virt.nix
  ];

  networking.hostId = "cc5b25a0";
  networking.hosts."10.11.11.2" = [ "haruka" ];

  boot.kernelParams = [ "zfs.zfs_arc_max=8589934592" ];

  services.tailscale.authKeyFile = config.age.secrets.tailscale.path;

  services.journald.extraConfig = "Storage=persistent";

  programs.nix-ld.enable = true;

  systemd.tmpfiles.rules = [
    "Z /hydrus 0755 juggeli users -"
  ];

  systemd.services.mount-tank = {
    description = "Mount tank network share for juggeli";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    unitConfig.StartLimitIntervalSec = 300;
    serviceConfig = {
      Type = "oneshot";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /home/juggeli/tank";
      ExecStart = "${pkgs.cifs-utils}/bin/mount.cifs //10.11.11.2/tank /home/juggeli/tank -o credentials=${config.age.secrets.smb.path},uid=1000,gid=100,iocharset=utf8";
      ExecStop = "${pkgs.util-linux}/bin/umount /home/juggeli/tank";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "30s";
      StartLimitBurst = 3;
    };
  };

  systemd.settings.Manager.DefaultTimeoutStopSec = "10s";

  services.udev.extraRules = ''
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0666", TAG+="uaccess", TAG+="udev-acl"
  '';

  hardware.i2c.enable = true;
  users.users.juggeli.extraGroups = [ "i2c" ];
  environment.systemPackages = [ pkgs.ddcutil ];

  system.stateVersion = "23.11";
}
