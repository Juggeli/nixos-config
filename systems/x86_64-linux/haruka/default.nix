{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  startpool = pkgs.writeShellScriptBin "startpool" ''
    doas zpool import tank
    doas zfs load-key -L file:///run/agenix/zfs tank
    doas zfs mount tank/media
    doas zfs mount tank/sorted
    doas zfs mount tank/hydrus
    doas zfs mount tank/documents
    doas zfs mount tank/backup
  '';

  startcontainers = pkgs.writeShellScriptBin "startcontainers" ''
    services=(
      "podman-plex.service"
      "podman-jellyfin.service"
      "podman-radarr.service"
      "podman-radarr-anime.service"
      "podman-sonarr.service"
      "podman-sonarr-anime.service"
      "podman-bazarr.service"
      "podman-trilium.service"
      "podman-uptime-kuma.service"
    )

    for service in "''${services[@]}"
    do
      gum spin -s line --title "Starting ''${service}..." --show-output -- doas systemctl start "$service"
    done

    echo "All services started successfully."
  '';

  stopcontainers = pkgs.writeShellScriptBin "stopcontainers" ''
    services=(
      "podman-plex.service"
      "podman-jellyfin.service"
      "podman-radarr.service"
      "podman-radarr-anime.service"
      "podman-sonarr.service"
      "podman-sonarr-anime.service"
      "podman-bazarr.service"
      "podman-trilium.service"
      "podman-uptime-kuma.service"
    )

    for service in "''${services[@]}"
    do
      gum spin -s line --title "Stopping ''${service}..." --show-output -- doas systemctl stop "$service"
    done

    echo "All services stopped successfully."
  '';

  backup = pkgs.callPackage ../../../packages/luks-backup {
    partitionUuids = [
      "585f6048-46df-4d11-a7f8-36a37b932a97"
      "b2fae3e5-97e0-425b-aa55-000eead6465e"
      "7064f0ca-116c-4ef8-af27-53f38552a492"
      "ed5f89cd-cf85-491a-b0f9-915d06d96465"
    ];
  };
in
{
  imports = [
    ./hardware.nix
    ./pool.nix
  ];

  environment.systemPackages = [
    startcontainers
    stopcontainers
    startpool
    backup
    pkgs.mergerfs
    pkgs.borgbackup
  ];

  programs.nix-ld.enable = true;

  plusultra = {
    feature = {
      syncthing = {
        enable = true;
        dataDir = "/mnt/appdata/syncthing";
      };
      borgmatic = {
        enable = true;
        backups = {
          storagebox = {
            directories = [ "/mnt/appdata" ];
            repository = {
              label = "storagebox";
              url_path = config.age.secrets.storagebox-url.path;
            };
            healthcheck_url_path = config.age.secrets.borg-healthcheck.path;
          };
        };
      };
      podman = enabled;
    };

    filesystem.zfs = enabled;

    hardware.storage = {
      enable = true;
      smartd.enable = true;
    };

    suites = {
      common-slim = enabled;
    };

    security = {
      acme = enabled;
    };
    tools.agenix = enabled;

    containers = {
      prowlarr = disabled;
      plex = {
        enable = true;
        homepage.widget = {
          enable = true;
        };
      };
      jellyfin = {
        enable = true;
        homepage = {
          url = "https://jelly.jugi.cc";
          widget = {
            enable = true;
          };
        };
      };
      qbittorrent = disabled;
      sonarr = {
        enable = true;
        homepage = {
          url = "https://sonarr.jugi.cc";
          widget = {
            enable = true;
          };
        };
      };
      sonarr-anime = {
        enable = true;
        homepage = {
          url = "https://sonarr-anime.jugi.cc";
          widget = {
            enable = true;
          };
        };
      };
      radarr = {
        enable = true;
        homepage = {
          url = "https://radarr.jugi.cc";
          widget = {
            enable = true;
          };
        };
      };
      radarr-anime = {
        enable = true;
        homepage = {
          url = "https://radarr-anime.jugi.cc";
          widget = {
            enable = true;
          };
        };
      };
      changedetection = disabled;
      trilium = enabled;
      grist = disabled;
      bazarr = {
        enable = true;
        homepage.widget = {
          enable = true;
        };
      };
      stash = disabled;
      uptime-kuma = {
        enable = true;
        homepage.widget = {
          enable = true;
        };
      };
    };

    services = {
      cockpit = disabled;
      cloudflared = enabled;
      grafana = disabled;
      homepage = enabled;
      prometheus = disabled;
      nfs = disabled;

      samba = {
        enable = true;
        shares = {
          tank = {
            path = "/tank";
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

  boot.kernelParams = [
    # try to fix zfs oom issue
    "zfs.zfs_arc_shrinker_limit=0"
    "zfs.zfs_arc_max=8589934592"
  ];

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
