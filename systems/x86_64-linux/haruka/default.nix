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
      "podman-prowlarr.service"
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
      "podman-prowlarr.service"
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
        versioning = {
          type = "staggered";
          params = {
            cleanInterval = "3600";
            maxAge = "2592000";
          };
        };
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
      av1an = {
        enable = true;
        sonarr.apiKeyFile = config.age.secrets.sonarr-anime-api.path;
      };
      prowlarr = {
        enable = true;
        homepage.widget.enable = true;
      };
      recyclarr = enabled;
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
      lanraragi = enabled;
      memos = enabled;
      sillytavern = enabled;
      uptime-kuma = {
        enable = true;
        homepage.widget = {
          enable = true;
        };
      };
      koto = {
        enable = true;
        environmentFile = config.age.secrets.koto-env.path;
        tailscale = {
          enable = true;
          authKeyFile = config.age.secrets.tailscale-auth.path;
        };
        settings = {
          dataDir = "/mnt/appdata/koto";
          embedding = {
            baseUrl = "https://api.synthetic.new/openai";
            model = "hf:nomic-ai/nomic-embed-text-v1.5";
          };
          webServer = {
            enabled = true;
            port = 9847;
          };
        };
      };
    };

    services = {
      cockpit = disabled;
      cloudflared = enabled;
      grafana = disabled;
      homepage.enable = true;
      prometheus = disabled;
      log-analyzer = enabled;
      qbittorrent-manager = {
        enable = true;
        connection = {
          host = "10.11.11.2";
          port = 8080;
          credentialsFile = config.age.secrets.qbittorrent-credentials.path;
        };
        limits = {
          publicRatio = 2.0;
          uploadLimitDownloading = 200000;
        };
        schedule = "minutely";
      };
      markdown-viewer = {
        enable = true;
        dataDir = "/mnt/appdata/second-brain";
        passwordFile = config.age.secrets.markdown-viewer-password.path;
      };
      nfs = disabled;

      sonarr-cleanup = {
        enable = true;
        sonarr = {
          url = "http://10.11.11.2:8989";
          apiKeyFile = config.age.secrets.sonarr-api.path;
        };
        jellyfin = {
          enable = true;
          url = "http://10.11.11.2:8096";
          apiKeyFile = config.age.secrets.jellyfin-api.path;
        };
        plex = {
          enable = true;
          url = "http://10.11.11.2:32400";
          tokenFile = config.age.secrets.plex-token.path;
        };
        ntfy.topicFile = config.age.secrets.ntfy-topic.path;
        dryRun = false;
      };

      radarr-cleanup = {
        enable = true;
        radarr = {
          url = "http://10.11.11.2:7878";
          apiKeyFile = config.age.secrets.radarr-api.path;
        };
        jellyfin = {
          enable = true;
          url = "http://10.11.11.2:8096";
          apiKeyFile = config.age.secrets.jellyfin-api.path;
        };
        plex = {
          enable = true;
          url = "http://10.11.11.2:32400";
          tokenFile = config.age.secrets.plex-token.path;
        };
        ntfy.topicFile = config.age.secrets.ntfy-topic.path;
        dryRun = false;
        whitelist = [
          "Survive Style 5+"
          "Battle Royale"
        ];
      };

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

  # Media group used by container services (sonarr, radarr, etc.) for shared file access
  users.groups.media.gid = 983;
  plusultra.user.extraGroups = [ "media" ];

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
