{ config, lib, ... }:
with lib;
with lib.plusultra; {
  imports = [
    ./hardware.nix
    ./pool.nix
  ];

  plusultra = {
    feature = {
      syncthing = enabled;
      borgmatic = {
        enable = true;
        directories = [
          "/mnt/appdata"
        ];
      };
    };

    filesystem.zfs = enabled;

    suites = {
      common-slim = enabled;
    };

    security = {
      acme = enabled;
    };
    tools.agenix = enabled;

    services = {
      cloudflared = enabled;
      grafana = disabled;
      prowlarr = enabled;
      plex = enabled;
      jellyfin = enabled;
      prometheus = disabled;
      qbittorrent = disabled;
      sonarr = enabled;
      homepage = enabled;
      radarr = enabled;
      cockpit = enabled;
      changedetection = enabled;
      trilium = enabled;
      nfs = enabled;
      grist = enabled;

      samba = {
        enable = true;
        shares = {
          pool = {
            path = "/mnt/pool";
            public = false;
            read-only = false;
          };
        };
      };
    };
    virtualisation = {
      podman = enabled;
    };
  };

  services.openssh = {
    enable = true;
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };

  networking = {
    interfaces.enp4s0.ipv4.addresses = [
      {
        address = "10.11.11.2";
        prefixLength = 24;
      }
    ];
    defaultGateway = "10.11.11.1";
    nameservers = [ "10.11.11.1" ];
    nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = "enp4s0";
    };
  };

  boot.kernelParams = [ "ip=10.11.11.2::10.11.11.1:255.255.255.0:haruka:enp4s0:off" ];

  boot.loader.supportsInitrdSecrets = true;
  boot.initrd = {
    luks.forceLuksSupportInInitrd = true;
    network.enable = true;
    preLVMCommands = lib.mkOrder 400 "sleep 1";
    network.ssh = {
      enable = true;
      port = 22;
      authorizedKeys = config.plusultra.services.openssh.authorizedKeys;
      hostKeys = [ /etc/ssh/ssh_host_ed25519_key ];
    };
    secrets = {
      "/etc/ssh/ssh_host_ed25519_key" = /etc/ssh/ssh_host_ed25519_key;
    };
    network.postCommands = ''
      echo 'cryptsetup-askpass' >> /root/.profile
    '';
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
