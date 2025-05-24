{ config, lib, ... }:

with lib;
with lib.plusultra;
let
  cfg = config.plusultra.services.homepage;
in
{
  options.plusultra.services.homepage = with types; {
    enable = mkBoolOpt false "Whether or not to enable homepage dashboard service.";
  };

  config = mkIf cfg.enable {
    services.homepage-dashboard = {
      enable = true;
      openFirewall = true;
      listenPort = 3000;
      environmentFile = config.age.secrets.homepage-env.path;
      services = [
        {
          "Apps" = mkMerge [
            (mkIf config.plusultra.containers.trilium.enable [
              {
                "Trilium" = {
                  href = "http://${config.networking.hostName}:8080";
                  icon = "trilium.png";
                };
              }
            ])
            (mkIf config.plusultra.containers.grist.enable [
              {
                "Grist" = {
                  href = "http://${config.networking.hostName}:8484";
                  icon = "grist.png";
                };
              }
            ])
          ];
        }
        {
          "Media" = mkMerge [
            (mkIf config.plusultra.containers.bazarr.enable [
              {
                "Bazarr" = {
                  href = "http://${config.networking.hostName}:6767";
                  icon = "bazarr.png";
                };
              }
            ])
            (mkIf config.plusultra.containers.sonarr.enable [
              {
                "Sonarr" = {
                  href = "http://${config.networking.hostName}:8989";
                  icon = "sonarr.png";
                };
              }
              {
                "Sonarr Anime" = {
                  href = "http://${config.networking.hostName}:8999";
                  icon = "sonarr.png";
                };
              }
            ])
            (mkIf config.plusultra.containers.radarr.enable [
              {
                "Radarr" = {
                  href = "http://${config.networking.hostName}:7878";
                  icon = "radarr.png";
                };
              }
              {
                "Radarr Anime" = {
                  href = "http://${config.networking.hostName}:7879";
                  icon = "radarr.png";
                };
              }
            ])
            (mkIf config.plusultra.containers.plex.enable [
              {
                "Plex" = {
                  href = "http://${config.networking.hostName}:32400";
                  icon = "plex.png";
                };
              }
            ])
            (mkIf config.plusultra.containers.jellyfin.enable [
              {
                "Jellyfin" = {
                  href = "http://${config.networking.hostName}:8096";
                  icon = "jellyfin.png";
                };
              }
            ])
            (mkIf config.plusultra.containers.prowlarr.enable [
              {
                "Prowlarr" = {
                  href = "http://${config.networking.hostName}:9696";
                  icon = "prowlarr.png";
                };
              }
            ])
            (mkIf config.plusultra.containers.qbittorrent.enable [
              {
                "qBittorrent" = {
                  href = "http://${config.networking.hostName}:9999";
                  icon = "qbittorrent.png";
                };
              }
            ])
            (mkIf config.plusultra.containers.stash.enable [
              {
                "Stash" = {
                  href = "http://${config.networking.hostName}:9999";
                  icon = "stash.png";
                };
              }
            ])
          ];
        }
        {
          "Monitoring" = mkMerge [
            (mkIf config.plusultra.containers.uptime-kuma.enable [
              {
                "Uptime Kuma" = {
                  href = "http://${config.networking.hostName}:3001";
                  icon = "uptime-kuma.png";
                };
              }
            ])
            (mkIf config.plusultra.containers.changedetection.enable [
              {
                "Change Detection" = {
                  href = "http://${config.networking.hostName}:5000";
                  icon = "changedetection.png";
                };
              }
            ])
          ];
        }
      ];
    };
  };
}
