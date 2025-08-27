{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
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
    backup
  ];

  programs.nix-ld.enable = true;

  systemd.targets.media-stack = {
    description = "Media server container stack";
    wantedBy = [ "multi-user.target" ];
    wants = [
      "podman-plex.service"
      "podman-jellyfin.service"
      "podman-radarr.service"
      "podman-radarr-anime.service"
      "podman-sonarr.service"
      "podman-sonarr-anime.service"
      "podman-bazarr.service"
      "podman-uptime-kuma.service"
    ];
    after = [
      "zfs-mount.service"
      "podman-plex.service"
      "podman-jellyfin.service"
      "podman-radarr.service"
      "podman-radarr-anime.service"
      "podman-sonarr.service"
      "podman-sonarr-anime.service"
      "podman-bazarr.service"
      "podman-uptime-kuma.service"
    ];
  };

  environment.shellAliases = {
    startcontainers = "sudo systemctl start media-stack.target";
    stopcontainers = "sudo systemctl stop media-stack.target";
    statuscontainers = "sudo systemctl status media-stack.target";
  };

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
    tools = {
      agenix = enabled;
      borgbackup = enabled;
    };

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
      qbittorrent = {
        enable = true;
        homepage = {
          widget = {
            enable = true;
          };
        };
      };
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
      trilium = disabled;
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
      homepage = {
        enable = true;
        misc = [
          {
            "Jellyfin" = {
              description = "Media server";
              href = "https://sweatpants.aiko.usbx.me/jellyfin";
              siteMonitor = "https://sweatpants.aiko.usbx.me/jellyfin/health";
              icon = "jellyfin.png";
              widget = {
                type = "jellyfin";
                url = "https://sweatpants.aiko.usbx.me/jellyfin";
                key = "{{HOMEPAGE_VAR_ULTRA_JELLYFIN_API_KEY}}";
                enableBlocks = true;
                enableNowPlaying = true;
              };
            };
          }
          {
            "Jellyseerr" = {
              description = "Media requests";
              href = "https://jellyseerr-sweatpants.aiko.usbx.me/";
              siteMonitor = "https://jellyseerr-sweatpants.aiko.usbx.me/";
              icon = "jellyseerr.png";
              widget = {
                type = "jellyseerr";
                url = "https://jellyseerr-sweatpants.aiko.usbx.me/";
                key = "{{HOMEPAGE_VAR_ULTRA_JELLYSEERR_API_KEY}}";
              };
            };
          }
          {
            "Overseerr" = {
              description = "Media requests";
              href = "https://overseerr-sweatpants.aiko.usbx.me/";
              siteMonitor = "https://overseerr-sweatpants.aiko.usbx.me/";
              icon = "overseerr.png";
              widget = {
                type = "overseerr";
                url = "https://overseerr-sweatpants.aiko.usbx.me/";
                key = "{{HOMEPAGE_VAR_ULTRA_OVERSEERR_API_KEY}}";
              };
            };
          }
          {
            "Plex" = {
              description = "Media streaming";
              href = "http://aiko-direct.usbx.me:12975/";
              siteMonitor = "http://aiko-direct.usbx.me:12975/";
              icon = "plex.png";
              widget = {
                type = "plex";
                url = "http://aiko-direct.usbx.me:12975/";
                key = "{{HOMEPAGE_VAR_ULTRA_PLEX_API_KEY}}";
              };
            };
          }
          {
            "Prowlarr" = {
              description = "Indexer manager";
              href = "https://sweatpants.aiko.usbx.me/prowlarr";
              siteMonitor = "https://sweatpants.aiko.usbx.me/prowlarr";
              icon = "prowlarr.png";
              widget = {
                type = "prowlarr";
                url = "https://sweatpants.aiko.usbx.me/prowlarr";
                key = "{{HOMEPAGE_VAR_ULTRA_PROWLARR_API_KEY}}";
              };
            };
          }
          {
            "qBittorrent" = {
              description = "BitTorrent client";
              href = "https://sweatpants.aiko.usbx.me/qbittorrent";
              siteMonitor = "https://sweatpants.aiko.usbx.me/qbittorrent";
              icon = "qbittorrent.png";
              widget = {
                type = "qbittorrent";
                url = "https://sweatpants.aiko.usbx.me/qbittorrent";
                username = "{{HOMEPAGE_VAR_ULTRA_QBITTORRENT_USERNAME}}";
                password = "{{HOMEPAGE_VAR_ULTRA_QBITTORRENT_PASSWORD}}";
              };
            };
          }
          {
            "Radarr" = {
              description = "Movie collection manager";
              href = "https://sweatpants.aiko.usbx.me/radarr";
              siteMonitor = "https://sweatpants.aiko.usbx.me/radarr";
              icon = "radarr.png";
              widget = {
                type = "radarr";
                url = "https://sweatpants.aiko.usbx.me/radarr";
                key = "{{HOMEPAGE_VAR_ULTRA_RADARR_API_KEY}}";
              };
            };
          }
          {
            "Sonarr" = {
              description = "TV series collection manager";
              href = "https://sweatpants.aiko.usbx.me/sonarr";
              siteMonitor = "https://sweatpants.aiko.usbx.me/sonarr";
              icon = "sonarr.png";
              widget = {
                type = "sonarr";
                url = "https://sweatpants.aiko.usbx.me/sonarr";
                key = "{{HOMEPAGE_VAR_ULTRA_SONARR_API_KEY}}";
              };
            };
          }
        ];
      };
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

  boot = {
    kernelParams = [
      # try to fix zfs oom issue
      "zfs.zfs_arc_shrinker_limit=0"
      "zfs.zfs_arc_max=8589934592"
    ];
    zfs.extraPools = [ "tank" ];
  };

  systemd.services.zfs-load-key = {
    description = "Load ZFS encryption key for tank pool";
    after = [
      "zfs-import.target"
      "agenix.service"
    ];
    wants = [ "zfs-import.target" ];
    wantedBy = [ "zfs-mount.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.zfs}/bin/zfs load-key -L file:///run/agenix/zfs tank";
    };
  };

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
