{
  pkgs,
  config,
  lib,
  channel,
  ...
}:
with lib;
with lib.plusultra; {
  imports = [
    ./hardware.nix
    ./autologin.nix
    ./virt.nix
  ];

  plusultra = {
    archetypes = {
      workstation = enabled;
    };
    tools.agenix = enabled;
    hardware.networking.hosts = {
      "10.11.11.2" = ["haruka"];
    };
    hardware.logitech = enabled;
    services.syncthing = {
      enable = true;
      dataDir = "/home/juggeli";
    };
  };

  # age.secrets.borg-passkey.file = "secrets/borg-passkey.age";
  services.borgbackup.jobs.homeRemote = mkBorgBackup {
    inherit config;
    paths = [
      "/home/juggeli/src/"
      "/home/juggeli/documents/"
      "/home/juggeli/Hydrus/"
    ];
  };

  fileSystems."/mnt/pool" = {
    device = "//10.11.11.2/pool";
    fsType = "cifs";
    options = let
      # this line prevents hanging on network split
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
    in ["${automount_opts},credentials=/etc/nixos/smb-secrets,uid=1001,gid=100"];
  };

  systemd.extraConfig = ''
    DefaultTimeoutStopSec=10s
  '';

  # For via and ledger app
  services.udev.extraRules = ''
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0666", TAG+="uaccess", TAG+="udev-acl"
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
}
