{
  flake.nixosModules.haruka-media-stack = {
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
  };
}
