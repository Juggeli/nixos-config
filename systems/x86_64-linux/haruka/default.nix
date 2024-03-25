{ config, lib, pkgs, ... }:
with lib;
with lib.plusultra; let
  ip = "10.11.11.2";
  gateway = "10.11.11.1";

  startcontainers = pkgs.writeShellScriptBin "startcontainers" ''
    services=(
      "podman-plex.service"
      "podman-jellyfin.service"
      "podman-radarr.service"
      "podman-radarr-anime.service"
      "podman-sonarr.service"
      "podman-sonarr-anime.service"
    )

    for service in "''${services[@]}"
    do
      gum spin -s line --title "Starting ''${service}..." --show-output -- doas systemctl start "$service"
    done

    echo "All services started successfully."
  '';
in
{
  imports = [
    ./hardware.nix
    ./pool.nix
  ];

  environment.systemPackages = [ startcontainers ];

  plusultra = {
    feature = {
      syncthing = enabled;
      borgmatic = {
        enable = true;
        directories = [
          "/mnt/appdata"
        ];
      };
      podman = enabled;
    };

    filesystem.zfs = enabled;

    suites = {
      common-slim = enabled;
    };

    security = {
      acme = enabled;
    };
    tools.agenix = enabled;

    containers = {
      prowlarr = enabled;
      plex = enabled;
      jellyfin = enabled;
      qbittorrent = disabled;
      sonarr = enabled;
      homepage = enabled;
      radarr = enabled;
      changedetection = enabled;
      trilium = enabled;
      grist = enabled;
    };

    services = {
      cockpit = enabled;
      cloudflared = enabled;
      grafana = disabled;
      prometheus = disabled;
      nfs = enabled;

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
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };

  services.nfs.server.exports = ''
    /mnt/disk1 100.66.172.75(rw)
  '';

  networking = {
    interfaces.enp4s0.ipv4.addresses = [
      {
        address = ip;
        prefixLength = 24;
      }
    ];
    defaultGateway = gateway;
    nameservers = [ gateway ];
  };

  boot.kernelParams = [ "ip=${ip}::${gateway}:255.255.255.0:haruka:enp4s0:off" ];

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
