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
    doas zfs mount tank/downloads
    doas zfs mount tank/documents
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

  backup = pkgs.writeShellScriptBin "backup" ''
    # List of UUIDs for your LUKS-encrypted partitions:
    PARTITIONS_UUIDS=(
      "585f6048-46df-4d11-a7f8-36a37b932a97"
      "b2fae3e5-97e0-425b-aa55-000eead6465e"
      "7064f0ca-116c-4ef8-af27-53f38552a492"
      "ed5f89cd-cf85-491a-b0f9-915d06d96465"
    )

    # Prefix for the LUKS mapping names:
    LUKS_MAPPER_PREFIX="crypt_disk"

    # Where each partition will be mounted (e.g., /mnt/disk1, /mnt/disk2, etc.)
    # The script will append an index to this base name.
    DISK_MOUNT_BASE="/mnt/disk"

    # The mergerfs mountpoint:
    MERGED_MOUNT="/mnt/disks"

    # The directory you want to copy from:
    SOURCE_DIR="/tank"

    ################################################################################
    # SCRIPT START
    ################################################################################

    set -e  # Exit on any error

    # Prompt once for the LUKS passphrase (no echo)
    read -sp "Enter LUKS passphrase: " LUKS_PASSWORD
    echo  # Just to move to a new line

    ################################################################################
    # 1. OPEN & MOUNT ALL LUKS PARTITIONS
    ################################################################################

    # Counter to keep track of each disk index
    COUNTER=1
    MOUNT_PATHS=()  # Will hold each mount path to feed into mergerfs later

    for UUID in "''${PARTITIONS_UUIDS[@]}"; do
      # Convert UUID to a known device path
      PART="/dev/disk/by-uuid/''${UUID}"
      
      # Create a name for the LUKS mapping
      MAPPER_NAME="''${LUKS_MAPPER_PREFIX}''${COUNTER}"
      
      echo "Opening LUKS partition with UUID=''${UUID} as /dev/mapper/''${MAPPER_NAME}..."
      # Feed the stored passphrase into cryptsetup via stdin
      echo -n "''${LUKS_PASSWORD}" | doas cryptsetup open "''${PART}" "''${MAPPER_NAME}" --type luks
      
      # Create a mount directory for this partition
      MOUNT_DIR="''${DISK_MOUNT_BASE}''${COUNTER}"
      doas mkdir -p "''${MOUNT_DIR}"
      
      echo "Mounting /dev/mapper/''${MAPPER_NAME} at ''${MOUNT_DIR}..."
      doas mount "/dev/mapper/''${MAPPER_NAME}" "''${MOUNT_DIR}"
      
      # Keep track of the mount path
      MOUNT_PATHS+=("''${MOUNT_DIR}")
      
      ((COUNTER++))
    done

    ################################################################################
    # 2. CREATE MERGERFS MOUNT
    ################################################################################

    # Make sure the mergerfs mount directory exists
    doas mkdir -p "''${MERGED_MOUNT}"

    # Join all mount paths with ':' for mergerfs
    MERGER_DIRS=''$(IFS=":"; echo "''${MOUNT_PATHS[*]}")

    echo "Creating mergerfs mount at ''${MERGED_MOUNT} combining: ''${MERGER_DIRS}"
    doas mergerfs "''${MERGER_DIRS}" "''${MERGED_MOUNT}" -o cache.files=off,dropcacheonclose=false,category.create=mfs

    ################################################################################
    # 3. RSYNC FROM /tank TO THE MERGERFS MOUNT
    ################################################################################

    echo "Copying data from ''${SOURCE_DIR} to ''${MERGED_MOUNT}..."
    doas rsync -avhP --delete "''${SOURCE_DIR}/" "''${MERGED_MOUNT}/"

    ################################################################################
    # 4. UNMOUNT EVERYTHING
    ################################################################################

    echo "Unmounting mergerfs mount at ''${MERGED_MOUNT}..."
    doas umount "''${MERGED_MOUNT}"

    # Close each LUKS container, unmount each partition
    COUNTER=1
    for UUID in "''${PARTITIONS_UUIDS[@]}"; do
      MAPPER_NAME="''${LUKS_MAPPER_PREFIX}''${COUNTER}"
      MOUNT_DIR="''${DISK_MOUNT_BASE}''${COUNTER}"
      
      echo "Unmounting ''${MOUNT_DIR}..."
      doas umount "''${MOUNT_DIR}"
      
      echo "Closing LUKS container /dev/mapper/''${MAPPER_NAME}..."
      doas cryptsetup close "''${MAPPER_NAME}"
      
      ((COUNTER++))
    done

    echo "All done!"
    exit 0
  '';
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
        directories = [ "/mnt/appdata" ];
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
