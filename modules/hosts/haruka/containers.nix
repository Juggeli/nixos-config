{
  flake.nixosModules.haruka-containers =
    { config, pkgs, ... }:
    let
      hotioBase = {
        labels."io.containers.autoupdate" = "registry";
        environment = {
          PUID = "1000";
          PGID = "983";
        };
      };

      kotoConfigFile = pkgs.writeText "config.json" (
        builtins.toJSON {
          dataDir = "/mnt/appdata/koto";
          embedding = {
            baseUrl = "https://api.synthetic.new/openai";
            model = "hf:nomic-ai/nomic-embed-text-v1.5";
          };
          webServer = {
            enabled = true;
            port = 9847;
          };
        }
      );

      kotoServeConfig = pkgs.writeText "koto-tailscale-serve.json" (
        builtins.toJSON {
          TCP = {
            "443" = {
              HTTPS = true;
            };
          };
          Web = {
            "\${TS_CERT_DOMAIN}:443" = {
              Handlers."/" = {
                Proxy = "http://127.0.0.1:9847";
              };
            };
          };
        }
      );
    in
    {
      virtualisation.oci-containers.containers = {
        prowlarr = hotioBase // {
          image = "ghcr.io/hotio/prowlarr";
          autoStart = false;
          ports = [ "9696:9696" ];
          volumes = [ "/mnt/appdata/prowlarr:/config" ];
        };

        plex = {
          image = "ghcr.io/hotio/plex";
          autoStart = false;
          ports = [ "32400:32400" ];
          labels."io.containers.autoupdate" = "registry";
          extraOptions = [
            ''--group-add="303"''
            "--device=/dev/dri/renderD128"
          ];
          volumes = [
            "/mnt/appdata/plex/:/config"
            "/tank/media/:/mnt/pool/media"
            "/mnt/appdata/plex-transcode/:/transcode"
          ];
        };

        jellyfin = {
          image = "ghcr.io/hotio/jellyfin";
          autoStart = false;
          ports = [ "8096:8096" ];
          labels."io.containers.autoupdate" = "registry";
          extraOptions = [
            ''--group-add="303"''
            "--device=/dev/dri/renderD128"
          ];
          volumes = [
            "/mnt/appdata/jellyfin/:/config"
            "/tank/media/:/media"
            "/mnt/appdata/transcode/:/transcode"
          ];
        };

        qbittorrent = {
          image = "ghcr.io/hotio/qbittorrent";
          autoStart = true;
          ports = [ "8080:8080" ];
          labels."io.containers.autoupdate" = "registry";
          volumes = [
            "/mnt/appdata/qbittorrent:/config"
            "/tank/media:/data"
          ];
          environment = {
            VPN_ENABLED = "true";
            VPN_PROVIDER = "proton";
            VPN_LAN_NETWORK = "10.11.11.0/24";
            VPN_CONF = "wg0";
            VPN_AUTO_PORT_FORWARD = "true";
            VPN_KEEP_LOCAL_DNS = "false";
            PRIVOXY_ENABLED = "false";
            PUID = "1000";
            PGID = "983";
          };
          extraOptions = [
            "--cap-add=NET_ADMIN"
            "--cap-add=NET_RAW"
            ''--sysctl="net.ipv6.conf.all.disable_ipv6=1"''
          ];
        };

        sonarr = hotioBase // {
          image = "ghcr.io/hotio/sonarr";
          autoStart = false;
          ports = [ "8989:8989" ];
          volumes = [
            "/mnt/appdata/sonarr/:/config/"
            "/tank/media/:/data"
          ];
        };

        sonarr-anime = hotioBase // {
          image = "ghcr.io/hotio/sonarr";
          autoStart = false;
          ports = [ "8999:8989" ];
          volumes = [
            "/mnt/appdata/sonarr-anime/:/config/"
            "/tank/media/:/data"
          ];
        };

        radarr = hotioBase // {
          image = "ghcr.io/hotio/radarr";
          autoStart = false;
          ports = [ "7878:7878" ];
          volumes = [
            "/mnt/appdata/radarr/:/config"
            "/tank/media/:/data"
          ];
        };

        radarr-anime = hotioBase // {
          image = "ghcr.io/hotio/radarr";
          autoStart = false;
          ports = [ "7879:7878" ];
          volumes = [
            "/mnt/appdata/radarr-anime/:/config"
            "/tank/media/:/data"
          ];
        };

        bazarr = {
          image = "ghcr.io/hotio/bazarr";
          autoStart = false;
          ports = [ "6767:6767" ];
          labels."io.containers.autoupdate" = "registry";
          environment = {
            PUID = "1000";
            PGID = "983";
            WEBUI_PORTS = "6767/tcp,6767/udp";
          };
          volumes = [
            "/mnt/appdata/bazarr/:/config"
            "/tank/media/:/mnt/pool/media/"
          ];
        };

        lanraragi = {
          image = "docker.io/difegue/lanraragi";
          autoStart = true;
          ports = [ "3333:3000" ];
          labels."io.containers.autoupdate" = "registry";
          volumes = [
            "/mnt/appdata/lanraragi:/home/koyomi/lanraragi/database"
            "/tank/documents/lanraragi:/home/koyomi/lanraragi/content"
            "/tank/documents/lanraragi/thumb:/home/koyomi/lanraragi/thumb"
          ];
        };

        memos = {
          image = "docker.io/neosmemo/memos:stable";
          autoStart = true;
          ports = [ "5230:5230" ];
          labels."io.containers.autoupdate" = "registry";
          volumes = [ "/mnt/appdata/memos:/var/opt/memos" ];
        };

        sillytavern = {
          image = "ghcr.io/sillytavern/sillytavern:latest";
          autoStart = true;
          ports = [ "8000:8000" ];
          labels."io.containers.autoupdate" = "registry";
          volumes = [
            "/mnt/appdata/sillytavern/config:/home/node/app/config"
            "/mnt/appdata/sillytavern/data:/home/node/app/data"
          ];
        };

        uptime-kuma = {
          image = "ghcr.io/louislam/uptime-kuma:2-rootless";
          autoStart = true;
          ports = [ "3001:3001" ];
          labels."io.containers.autoupdate" = "registry";
          volumes = [ "/mnt/appdata/uptime-kuma:/app/data" ];
          environment = {
            PUID = "1000";
            PGID = "100";
          };
          extraOptions = [ "--cap-add=NET_RAW" ];
        };

        tailscale-koto = {
          image = "docker.io/tailscale/tailscale:latest";
          autoStart = true;
          environment = {
            TS_AUTHKEY = "file:/run/secrets/tailscale-authkey";
            TS_HOSTNAME = "koto";
            TS_STATE_DIR = "/var/lib/tailscale";
            TS_SERVE_CONFIG = "/config/serve.json";
            TS_USERSPACE = "false";
          };
          volumes = [
            "/mnt/appdata/koto/tailscale:/var/lib/tailscale"
            "${kotoServeConfig}:/config/serve.json:ro"
            "${config.age.secrets.tailscale-auth.path}:/run/secrets/tailscale-authkey:ro"
          ];
          extraOptions = [
            "--cap-add=NET_ADMIN"
            "--cap-add=NET_RAW"
            "--device=/dev/net/tun:/dev/net/tun"
          ];
          labels."io.containers.autoupdate" = "registry";
        };

        koto = {
          image = "ghcr.io/juggeli/koto:latest";
          autoStart = true;
          extraOptions = [ "--network=container:tailscale-koto" ];
          labels."io.containers.autoupdate" = "registry";
          volumes = [
            "/mnt/appdata/koto:/mnt/appdata/koto"
            "${kotoConfigFile}:/app/config.json:ro"
          ];
          environmentFiles = [ config.age.secrets.koto-env.path ];
          dependsOn = [ "tailscale-koto" ];
        };
      };

      systemd.services.podman-koto = {
        after = [ "podman-tailscale-koto.service" ];
        serviceConfig.ExecStartPre = [
          "${pkgs.bash}/bin/bash -c 'for i in $(seq 1 30); do ${pkgs.libressl.nc}/bin/nc -z -w1 10.88.0.1 53 && exit 0; sleep 1; done; echo \"aardvark-dns not ready after 30s\"; exit 1'"
        ];
      };

      systemd.services.podman-qbittorrent.serviceConfig.ExecStartPre = [
        "${pkgs.coreutils}/bin/rm -f /mnt/appdata/qbittorrent/config/ipc-socket /mnt/appdata/qbittorrent/config/lockfile"
      ];

      boot.kernel.sysctl."net.ipv4.conf.all.src_valid_mark" = 1;

      services.recyclarr = {
        enable = true;
        configuration = {
          sonarr = {
            anime-sonarr-v4 = {
              base_url = "http://haruka:8999";
              api_key._secret = config.age.secrets.sonarr-anime-api.path;

              include = [
                { template = "sonarr-quality-definition-anime"; }
                { template = "sonarr-v4-custom-formats-anime"; }
              ];

              quality_profiles = [
                {
                  name = "Remux-1080p - Anime";
                  reset_unmatched_scores.enabled = true;
                  upgrade = {
                    allowed = true;
                    until_quality = "1080p";
                    until_score = 10000;
                  };
                  min_format_score = 100;
                  score_set = "anime-sonarr";
                  quality_sort = "top";
                  qualities = [
                    {
                      name = "1080p";
                      qualities = [
                        "Bluray-1080p"
                        "WEBDL-1080p"
                        "WEBRip-1080p"
                        "HDTV-1080p"
                      ];
                    }
                    { name = "Bluray-720p"; }
                    {
                      name = "WEB 720p";
                      qualities = [
                        "WEBDL-720p"
                        "WEBRip-720p"
                        "HDTV-720p"
                      ];
                    }
                    { name = "Bluray-480p"; }
                    {
                      name = "WEB 480p";
                      qualities = [
                        "WEBDL-480p"
                        "WEBRip-480p"
                      ];
                    }
                    { name = "DVD"; }
                    { name = "SDTV"; }
                  ];
                }
              ];

              custom_formats = [
                {
                  trash_ids = [ "026d5aadd1a6b4e550b134cb6c72b3ca" ];
                  assign_scores_to = [
                    {
                      name = "Remux-1080p - Anime";
                      score = 2000;
                    }
                  ];
                }
                {
                  trash_ids = [ "b2550eb333d27b75833e25b8c2557b38" ];
                  assign_scores_to = [
                    {
                      name = "Remux-1080p - Anime";
                      score = 10;
                    }
                  ];
                }
              ];
            };

            web-2160p-v4 = {
              base_url = "http://haruka:8989/";
              api_key._secret = config.age.secrets.sonarr-api.path;

              include = [
                { template = "sonarr-quality-definition-series"; }
                { template = "sonarr-v4-quality-profile-web-2160p"; }
                { template = "sonarr-v4-custom-formats-web-2160p"; }
              ];

              quality_profiles = [
                {
                  name = "WEB-2160p";
                  upgrade = {
                    allowed = true;
                    until_quality = "WEB 2160p";
                    until_score = 10000;
                  };
                  min_format_score = 0;
                  quality_sort = "top";
                  qualities = [
                    {
                      name = "WEB 2160p";
                      qualities = [
                        "WEBDL-2160p"
                        "WEBRip-2160p"
                      ];
                    }
                    {
                      name = "WEB 1080p";
                      qualities = [
                        "WEBDL-1080p"
                        "WEBRip-1080p"
                      ];
                    }
                  ];
                }
              ];

              custom_formats = [
                {
                  trash_ids = [ "9b27ab6498ec0f31a3353992e19434ca" ];
                  assign_scores_to = [ { name = "WEB-2160p"; } ];
                }
                {
                  trash_ids = [
                    "32b367365729d530ca1c124a0b180c64"
                    "82d40da2bc6923f41e14394075dd4b03"
                    "e1a997ddb54e3ecbfe06341ad323c458"
                    "06d66ab109d4d2eddb2794d21526d140"
                  ];
                  assign_scores_to = [ { name = "WEB-2160p"; } ];
                }
                {
                  trash_ids = [ "47435ece6b99a0b477caf360e79ba0bb" ];
                  assign_scores_to = [
                    {
                      name = "WEB-2160p";
                      score = 0;
                    }
                  ];
                }
                {
                  trash_ids = [ "9b64dff695c2115facf1b6ea59c9bd07" ];
                  assign_scores_to = [ { name = "WEB-2160p"; } ];
                }
                {
                  trash_ids = [ "83304f261cf516bb208c18c54c0adf97" ];
                  assign_scores_to = [ { name = "WEB-2160p"; } ];
                }
              ];
            };
          };
        };
      };
    };
}
