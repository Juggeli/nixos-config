{
  flake.nixosModules.haruka-homepage =
    { config, ... }:
    let
      hostUrl = port: "http://${config.networking.hostName}:${toString port}";

      mkWidget =
        {
          envKeyName,
          type,
          url,
          fields ? null,
          enableBlocks ? null,
          slug ? null,
        }:
        {
          inherit type url;
          key = "{{HOMEPAGE_VAR_${envKeyName}_API_KEY}}";
        }
        // (if fields != null then { inherit fields; } else { })
        // (if enableBlocks != null then { inherit enableBlocks; } else { })
        // (if slug != null then { inherit slug; } else { });
    in
    {
      services.glances.enable = true;

      services.homepage-dashboard = {
        enable = true;
        openFirewall = true;
        listenPort = 3000;

        customCSS = ''
          body, html {
            font-family: SF Pro Display, Helvetica, Arial, sans-serif !important;
          }
          .font-medium {
            font-weight: 700 !important;
          }
          .font-light {
            font-weight: 500 !important;
          }
          .font-thin {
            font-weight: 400 !important;
          }
          #information-widgets {
            padding-left: 1.5rem;
            padding-right: 1.5rem;
          }
          div#footer {
            display: none;
          }
          .services-group.basis-full.flex-1.px-1.-my-1 {
            padding-bottom: 3rem;
          }
        '';

        settings = {
          layout = [
            {
              System = {
                header = false;
                style = "row";
                columns = 4;
              };
            }
            {
              Apps = {
                header = true;
                style = "column";
              };
            }
            {
              Downloads = {
                header = true;
                style = "column";
              };
            }
            {
              Media = {
                header = true;
                style = "column";
              };
            }
            {
              Monitoring = {
                header = true;
                style = "column";
              };
            }
            {
              Other = {
                header = true;
                style = "column";
              };
            }
          ];
          headerStyle = "clean";
          statusStyle = "dot";
          hideVersion = true;
        };

        environmentFile = config.age.secrets.homepage-env.path;

        services = [
          {
            Apps = [
              {
                SillyTavern = {
                  icon = "sillytavern.png";
                  description = "LLM frontend";
                  href = hostUrl 8000;
                  siteMonitor = hostUrl 8000;
                };
              }
            ];
          }
          {
            Downloads = [
              {
                qBittorrent = {
                  icon = "qbittorrent.png";
                  description = "Torrent client";
                  href = hostUrl 8080;
                  siteMonitor = hostUrl 8080;
                  widget = mkWidget {
                    envKeyName = "QBITTORRENT";
                    type = "qbittorrent";
                    url = hostUrl 8080;
                    fields = [
                      "leech"
                      "download"
                      "seed"
                      "upload"
                    ];
                  };
                };
              }
            ];
          }
          {
            Media = [
              {
                Bazarr = {
                  icon = "bazarr.png";
                  description = "Subtitle management";
                  href = hostUrl 6767;
                  siteMonitor = hostUrl 6767;
                  widget = mkWidget {
                    envKeyName = "BAZARR";
                    type = "bazarr";
                    url = hostUrl 6767;
                    fields = [
                      "missingEpisodes"
                      "missingMovies"
                    ];
                  };
                };
              }
              {
                Jellyfin = {
                  icon = "jellyfin.png";
                  description = "Media server";
                  href = "https://jelly.jugi.cc";
                  siteMonitor = "https://jelly.jugi.cc";
                  widget = mkWidget {
                    envKeyName = "JELLYFIN";
                    type = "jellyfin";
                    url = "https://jelly.jugi.cc";
                    enableBlocks = true;
                    fields = [
                      "movies"
                      "series"
                      "episodes"
                      "songs"
                    ];
                  };
                };
              }
              {
                LANraragi = {
                  icon = "lanraragi.png";
                  description = "Archive reader";
                  href = hostUrl 3333;
                  siteMonitor = hostUrl 3333;
                };
              }
              {
                Plex = {
                  icon = "plex.png";
                  description = "Media server";
                  href = hostUrl 32400;
                  siteMonitor = hostUrl 32400;
                  widget = mkWidget {
                    envKeyName = "PLEX";
                    type = "plex";
                    url = hostUrl 32400;
                    fields = [
                      "streams"
                      "movies"
                      "tv"
                    ];
                  };
                };
              }
              {
                Prowlarr = {
                  icon = "prowlarr.png";
                  description = "Indexer manager";
                  href = hostUrl 9696;
                  siteMonitor = hostUrl 9696;
                  widget = mkWidget {
                    envKeyName = "PROWLARR";
                    type = "prowlarr";
                    url = hostUrl 9696;
                    fields = [
                      "numberOfGrabs"
                      "numberOfQueries"
                      "numberOfFailGrabs"
                      "numberOfFailQueries"
                    ];
                  };
                };
              }
              {
                Radarr = {
                  icon = "radarr.png";
                  description = "Movie management";
                  href = "https://radarr.jugi.cc";
                  siteMonitor = "https://radarr.jugi.cc";
                  widget = mkWidget {
                    envKeyName = "RADARR";
                    type = "radarr";
                    url = "https://radarr.jugi.cc";
                    fields = [
                      "wanted"
                      "missing"
                      "queued"
                      "movies"
                    ];
                  };
                };
              }
              {
                "Radarr Anime" = {
                  icon = "radarr.png";
                  description = "Anime movie management";
                  href = "https://radarr-anime.jugi.cc";
                  siteMonitor = "https://radarr-anime.jugi.cc";
                  widget = mkWidget {
                    envKeyName = "RADARR_ANIME";
                    type = "radarr";
                    url = "https://radarr-anime.jugi.cc";
                    fields = [
                      "wanted"
                      "missing"
                      "queued"
                      "movies"
                    ];
                  };
                };
              }
              {
                Sonarr = {
                  icon = "sonarr.png";
                  description = "TV show management";
                  href = "https://sonarr.jugi.cc";
                  siteMonitor = "https://sonarr.jugi.cc";
                  widget = mkWidget {
                    envKeyName = "SONARR";
                    type = "sonarr";
                    url = "https://sonarr.jugi.cc";
                    fields = [
                      "wanted"
                      "queued"
                      "series"
                    ];
                  };
                };
              }
              {
                "Sonarr Anime" = {
                  icon = "sonarr.png";
                  description = "Anime TV show management";
                  href = "https://sonarr-anime.jugi.cc";
                  siteMonitor = "https://sonarr-anime.jugi.cc";
                  widget = mkWidget {
                    envKeyName = "SONARR_ANIME";
                    type = "sonarr";
                    url = "https://sonarr-anime.jugi.cc";
                    fields = [
                      "wanted"
                      "queued"
                      "series"
                    ];
                  };
                };
              }
            ];
          }
          {
            Monitoring = [
              {
                "Uptime Kuma" = {
                  icon = "uptime-kuma.png";
                  description = "Status monitoring";
                  href = hostUrl 3001;
                  siteMonitor = hostUrl 3001;
                  widget = mkWidget {
                    envKeyName = "UPTIME_KUMA";
                    type = "uptimekuma";
                    url = hostUrl 3001;
                    slug = "ultra";
                    fields = [
                      "up"
                      "down"
                      "uptime"
                      "incident"
                    ];
                  };
                };
              }
            ];
          }
          {
            Other = [
              {
                Koto = {
                  icon = "robot.png";
                  description = "Personal AI assistant";
                  href = hostUrl 9847;
                  siteMonitor = hostUrl 9847;
                };
              }
              {
                Memos = {
                  icon = "memos.png";
                  description = "Privacy-first note-taking app";
                  href = hostUrl 5230;
                  siteMonitor = hostUrl 5230;
                };
              }
            ];
          }
          {
            System =
              let
                port = toString config.services.glances.port;
              in
              [
                {
                  Info.widget = {
                    type = "glances";
                    url = "http://localhost:${port}";
                    metric = "info";
                    chart = false;
                    version = 4;
                  };
                }
                {
                  "CPU Temp".widget = {
                    type = "glances";
                    url = "http://localhost:${port}";
                    metric = "sensor:Package id 0";
                    chart = false;
                    version = 4;
                  };
                }
                {
                  Processes.widget = {
                    type = "glances";
                    url = "http://localhost:${port}";
                    metric = "process";
                    chart = false;
                    version = 4;
                  };
                }
                {
                  Network.widget = {
                    type = "glances";
                    url = "http://localhost:${port}";
                    metric = "network:enp1s0";
                    chart = false;
                    version = 4;
                  };
                }
                {
                  "tank/backup".widget = {
                    type = "glances";
                    url = "http://localhost:${port}";
                    metric = "fs:/tank/backup";
                    chart = false;
                    version = 4;
                    diskUnits = "bytes";
                  };
                }
                {
                  "tank/documents".widget = {
                    type = "glances";
                    url = "http://localhost:${port}";
                    metric = "fs:/tank/documents";
                    chart = false;
                    version = 4;
                    diskUnits = "bytes";
                  };
                }
                {
                  "tank/media".widget = {
                    type = "glances";
                    url = "http://localhost:${port}";
                    metric = "fs:/tank/media";
                    chart = false;
                    version = 4;
                    diskUnits = "bytes";
                  };
                }
                {
                  "tank/sorted".widget = {
                    type = "glances";
                    url = "http://localhost:${port}";
                    metric = "fs:/tank/sorted";
                    chart = false;
                    version = 4;
                    diskUnits = "bytes";
                  };
                }
              ];
          }
        ];
      };
    };
}
