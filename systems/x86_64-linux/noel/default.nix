{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
{
  imports = [
    ./hardware.nix
    ./autologin.nix
    ./disk-config.nix
  ];

  plusultra = {
    feature = {
      boot = enabled;
      theming = enabled;
      syncthing = enabled;
      borgmatic = {
        enable = true;
        backups = {
          storagebox = {
            directories = [
              "/persist/"
              "/persist-home/"
            ];
            repository = {
              url_path = config.age.secrets.storagebox-url.path;
              label = "storagebox";
            };
            healthcheck_url_path = config.age.secrets.borg-healthcheck.path;
          };
          hydrus = {
            directories = [ "/hydrus" ];
            repository = {
              url = "ssh://juggeli@haruka/tank/backup/hydrus";
              label = "haruka-hydrus";
            };
            healthcheck_url_path = config.age.secrets.borg-hydrus-healthcheck.path;
          };
        };
      };
    };
    filesystem = {
      btrfs = enabled;
      encryption = enabled;
      impermanence = enabled;
      tmpfs = enabled;
    };
    suites = {
      common = enabled;
      desktop = enabled;
      development = enabled;
      social = enabled;
      media = enabled;
    };
    apps.gaming = enabled;
    tools.agenix = enabled;
    hardware = {
      networking.hosts = {
        "10.11.11.2" = [ "haruka" ];
      };
      logitech = enabled;
    };
    services = {
      tailscale = {
        enable = true;
        autoconnect = {
          enable = true;
          key = config.age.secrets.tailscale.path;
        };
      };
      kdeconnect = enabled;
    };
  };

  programs.nix-ld.enable = true;

  systemd.services.mount-tank = {
    description = "Mount tank network share for juggeli";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /home/juggeli/tank";
      ExecStart = "${pkgs.cifs-utils}/bin/mount.cifs //10.11.11.2/tank /home/juggeli/tank -o credentials=${config.age.secrets.smb.path},uid=1000,gid=100,iocharset=utf8";
      ExecStop = "${pkgs.util-linux}/bin/umount /home/juggeli/tank";
      RemainAfterExit = true;
    };
  };

  systemd.extraConfig = ''
    DefaultTimeoutStopSec=10s
  '';

  # For via and ledger app
  services.udev.extraRules = ''
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0666", TAG+="uaccess", TAG+="udev-acl"
  '';

  hardware.i2c.enable = true;
  environment.systemPackages = with pkgs; [ ddcutil ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
