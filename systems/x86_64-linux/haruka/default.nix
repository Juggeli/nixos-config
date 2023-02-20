{ pkgs, config, lib, channel, ... }:

with lib;
with lib.internal;
{
  imports = [
    ./hardware.nix
    ./pool.nix
  ];

  plusultra = {
    archetypes = {
      server = enabled;
    };

    security = {
      acme = enabled;
    };

    services = {
      cloudflared = enabled;
      grafana = enabled;
      homeassistant = enabled;
      jackett = enabled;
      plex = enabled;
      prometheus = enabled;
      qbittorrent = enabled;
      sonarr = enabled;
      unifi = enabled;
      
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
  };

  services.openssh = {
    enable = true;
    hostKeys = [{
      path = "/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }];
  };

  networking.interfaces.enp3s0.ipv4.addresses = [{
    address = "10.11.11.2";
    prefixLength = 24;
  }];
  networking.defaultGateway = "10.11.11.1";
  networking.nameservers = [ "1.1.1.1" ];

  boot.kernelParams = [ "ip=10.11.11.2::10.11.11.1:255.255.255.0:haruka:enp3s0:off" ];

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
  system.stateVersion = "21.11"; # Did you read the comment?
}

