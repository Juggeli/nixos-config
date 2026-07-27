{
  flake.nixosModules.haruka-containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # Images update unattended, so a compromised upstream reaches the host with
      # no review step. no-new-privileges is the one restriction that holds across
      # every image here, including the s6-based hotio ones that start as root and
      # drop to PUID: that drop is a setuid() call, which the flag does not block.
      hardened = [ "--security-opt=no-new-privileges" ];

      # Shared XDG_RUNTIME_DIR for every podman invocation that touches the
      # oci user's storage: containers/storage wants one run root per graph
      # root, and the fallback it would otherwise pick (/tmp/storage-run-2000)
      # is subject to the 10-day /tmp cleanup, which corrupts podman's state
      # under a running stack. Podman pins the run root it first saw in its
      # database and silently ignores a changed environment, so moving this
      # path means stopping every container and deleting storage/db.sql.
      ociRuntimeDir = "/run/oci-podman";

      # Upstream references the soak timer watches. Each is republished locally
      # as localhost/<name>:pinned once its digest has been public for the soak
      # period, and that local tag is what the containers below actually run.
      # koto is absent on purpose: it is first-party, so there is no upstream to
      # distrust and no reason to delay our own deploys by three days.
      soakedImages = {
        prowlarr = "ghcr.io/hotio/prowlarr:latest";
        plex = "ghcr.io/hotio/plex:latest";
        jellyfin = "ghcr.io/hotio/jellyfin:latest";
        qbittorrent = "ghcr.io/hotio/qbittorrent:latest";
        sonarr = "ghcr.io/hotio/sonarr:latest";
        radarr = "ghcr.io/hotio/radarr:latest";
        bazarr = "ghcr.io/hotio/bazarr:latest";
        lanraragi = "docker.io/difegue/lanraragi:latest";
        memos = "docker.io/neosmemo/memos:stable";
        sillytavern = "ghcr.io/sillytavern/sillytavern:latest";
        tailscale = "docker.io/tailscale/tailscale:latest";
      };

      # A registry pull policy would defeat the soak by pulling the tag itself,
      # so these follow the local tag and let the soak service decide what it
      # holds. The soak also restarts running units after a promotion, so no
      # autoupdate label is needed.
      soaked = name: {
        image = "localhost/${name}:pinned";
        pull = "never";
        podman.user = "oci";
      };

      # The app inside runs as a fixed non-root uid; mapping the oci user onto
      # exactly that uid keeps host-side file ownership at oci:media instead of
      # scattering it across the subuid range. keep-id would also default the
      # container process to that mapped user, but these images must still
      # start as container root (a subuid on the host) and drop privileges
      # themselves, hence the explicit --user. Containers whose payload runs as
      # container root need no mapping: rootless podman already maps container
      # root onto the invoking user.
      idmap = uid: gid: [
        "--userns=keep-id:uid=${toString uid},gid=${toString gid}"
        "--user=0:0"
      ];

      # The arr apps resolve each other and qbittorrent by container name.
      # Rootless aardvark-dns needs a systemd user bus that system units do not
      # have, so the shared network runs DNS-less with static addresses and
      # /etc/hosts entries instead. Plex and Jellyfin deliberately stay off it:
      # on the default pasta network inbound connections keep their LAN source
      # addresses, which Plex uses to tell local players from remote.
      mediaHosts = {
        qbittorrent = "10.90.0.10";
        prowlarr = "10.90.0.11";
        sonarr = "10.90.0.12";
        sonarr-anime = "10.90.0.13";
        radarr = "10.90.0.14";
        radarr-anime = "10.90.0.15";
        bazarr = "10.90.0.16";
      };
      mediaNetMembers = lib.attrNames mediaHosts;
      mediaNetOptions =
        name:
        [ "--network=media:ip=${mediaHosts.${name}}" ]
        ++ lib.mapAttrsToList (n: ip: "--add-host=${n}:${ip}") mediaHosts;

      hotioFor = name: {
        extraOptions = hardened ++ idmap 1000 983 ++ mediaNetOptions name;
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
        prowlarr =
          hotioFor "prowlarr"
          // soaked "prowlarr"
          // {
            autoStart = false;
            ports = [ "9696:9696" ];
            volumes = [ "/mnt/appdata/prowlarr:/config" ];
          };

        # Plex and Jellyfin keep a LAN-wide binding: local players discover and
        # direct-play against them, which an HTTPS proxy in front would break.
        # renderD128 is world-rw, so the device works without a group-add
        # (host groups are not mapped into the user namespace anyway).
        plex = soaked "plex" // {
          autoStart = false;
          ports = [ "32400:32400" ];
          environment = {
            PUID = "1000";
            PGID = "983";
          };
          extraOptions = hardened ++ idmap 1000 983 ++ [ "--device=/dev/dri/renderD128" ];
          volumes = [
            "/mnt/appdata/plex/:/config"
            "/tank/media/:/mnt/pool/media:ro"
            "/mnt/appdata/plex-transcode/:/transcode"
          ];
        };

        jellyfin = soaked "jellyfin" // {
          autoStart = false;
          ports = [ "8096:8096" ];
          environment = {
            PUID = "1000";
            PGID = "983";
          };
          extraOptions = hardened ++ idmap 1000 983 ++ [ "--device=/dev/dri/renderD128" ];
          volumes = [
            "/mnt/appdata/jellyfin/:/config"
            "/tank/media/:/media:ro"
            "/mnt/appdata/transcode/:/transcode"
          ];
        };

        qbittorrent = soaked "qbittorrent" // {
          autoStart = true;
          ports = [ "8080:8080" ];
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
          # The network capabilities and sysctl are scoped to the container's
          # own user and network namespaces, so rootless can still grant them.
          extraOptions =
            hardened
            ++ idmap 1000 983
            ++ mediaNetOptions "qbittorrent"
            ++ [
              "--cap-add=NET_ADMIN"
              "--cap-add=NET_RAW"
              ''--sysctl="net.ipv6.conf.all.disable_ipv6=1"''
            ];
        };

        sonarr =
          hotioFor "sonarr"
          // soaked "sonarr"
          // {
            autoStart = false;
            ports = [ "8989:8989" ];
            volumes = [
              "/mnt/appdata/sonarr/:/config/"
              "/tank/media/:/data"
            ];
          };

        sonarr-anime =
          hotioFor "sonarr-anime"
          // soaked "sonarr"
          // {
            autoStart = false;
            ports = [ "8999:8989" ];
            volumes = [
              "/mnt/appdata/sonarr-anime/:/config/"
              "/tank/media/:/data"
            ];
          };

        radarr =
          hotioFor "radarr"
          // soaked "radarr"
          // {
            autoStart = false;
            ports = [ "7878:7878" ];
            volumes = [
              "/mnt/appdata/radarr/:/config"
              "/tank/media/:/data"
            ];
          };

        radarr-anime =
          hotioFor "radarr-anime"
          // soaked "radarr"
          // {
            autoStart = false;
            ports = [ "7879:7878" ];
            volumes = [
              "/mnt/appdata/radarr-anime/:/config"
              "/tank/media/:/data"
            ];
          };

        bazarr = soaked "bazarr" // {
          autoStart = false;
          ports = [ "6767:6767" ];
          extraOptions = hardened ++ idmap 1000 983 ++ mediaNetOptions "bazarr";
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

        lanraragi = soaked "lanraragi" // {
          autoStart = true;
          ports = [ "3333:3000" ];
          # lanraragi drops to its koyomi user (9001) for the app
          extraOptions = hardened ++ idmap 9001 9001;
          volumes = [
            "/mnt/appdata/lanraragi:/home/koyomi/lanraragi/database"
            "/tank/documents/lanraragi:/home/koyomi/lanraragi/content"
            "/tank/documents/lanraragi/thumb:/home/koyomi/lanraragi/thumb"
          ];
        };

        memos = soaked "memos" // {
          autoStart = true;
          ports = [ "127.0.0.1:5230:5230" ];
          # memos runs as uid 10001 inside
          extraOptions = hardened ++ idmap 10001 10001;
          volumes = [ "/mnt/appdata/memos:/var/opt/memos" ];
        };

        sillytavern = soaked "sillytavern" // {
          autoStart = true;
          ports = [ "8000:8000" ];
          extraOptions = hardened;
          volumes = [
            "/mnt/appdata/sillytavern/config:/home/node/app/config"
            "/mnt/appdata/sillytavern/data:/home/node/app/data"
          ];
        };

        tailscale-koto = soaked "tailscale" // {
          autoStart = true;
          environment = {
            TS_AUTHKEY = "file:/run/secrets/tailscale-authkey";
            TS_HOSTNAME = "koto";
            TS_STATE_DIR = "/var/lib/tailscale";
            TS_SERVE_CONFIG = "/config/serve.json";
            # Userspace netstack rather than a tun device: this sidecar only
            # terminates tailnet connections and proxies them to koto over the
            # shared loopback, which serve does entirely in userspace. That drops
            # the tun device and both network capabilities.
            TS_USERSPACE = "true";
          };
          volumes = [
            "/mnt/appdata/koto/tailscale:/var/lib/tailscale"
            "${kotoServeConfig}:/config/serve.json:ro"
            "${config.age.secrets.tailscale-auth.path}:/run/secrets/tailscale-authkey:ro"
          ];
          extraOptions = hardened;
        };

        koto = {
          image = "ghcr.io/juggeli/koto:latest";
          autoStart = true;
          podman.user = "oci";
          extraOptions = hardened ++ [ "--network=container:tailscale-koto" ];
          volumes = [
            "/mnt/appdata/koto:/mnt/appdata/koto"
            "${kotoConfigFile}:/app/config.json:ro"
          ];
          environmentFiles = [ config.age.secrets.koto-env.path ];
          dependsOn = [ "tailscale-koto" ];
        };
      };

      virtualisation.podmanImageSoak = {
        enable = true;
        soakDays = 3;
        user = "oci";
        runtimeDir = ociRuntimeDir;
        images = soakedImages;
        notifyCommand = ''
          ${pkgs.curl}/bin/curl -s \
            -H "Title: Container image soak" \
            -H "Priority: high" \
            -H "Tags: warning,package" \
            --data-binary @- \
            "https://ntfy.sh/$(cat ${config.age.secrets.ntfy-topic.path})"
        '';
      };

      # The container escape surface is the auto-updated upstream images, so
      # they run rootless under a dedicated user: an escape lands in an account
      # that owns nothing but the container state, not root or the login user.
      users.users.oci = {
        isSystemUser = true;
        # Static: file ownership on appdata and the keep-id mappings depend on it.
        uid = 2000;
        group = "media";
        home = "/mnt/appdata/oci";
        createHome = true;
        # The containers are system units with User=oci, not user-session
        # units, so no lingering user manager is needed (and the oci-containers
        # module warns when it is combined with the default sdnotify=conmon).
        linger = false;
        # Must not overlap juggeli's subordinate range (100000+65536).
        subUidRanges = [
          {
            startUid = 300000;
            count = 65536;
          }
        ];
        subGidRanges = [
          {
            startGid = 300000;
            count = 65536;
          }
        ];
      };

      # Read by podman itself (env files, mounted secret) as the oci user.
      age.secrets = {
        tailscale-auth.owner = "oci";
        koto-env.owner = "oci";
        ntfy-topic.owner = "oci";
      };

      # Rootless publishing binds real host sockets, so networking.firewall
      # applies to container ports. The web UIs are tailnet-only: enp1s0
      # carries globally routable IPv6 alongside the LAN, so any port opened
      # on it is open to the Internet, and every host-side consumer
      # (cloudflared, recyclarr, homepage probes) uses loopback anyway. Plex
      # and Jellyfin are the exception — LAN players direct-play against
      # them — and are admitted by source subnet because interface scoping
      # cannot separate the LAN from public IPv6 on the same interface.
      networking.firewall = {
        interfaces.tailscale0.allowedTCPPorts = [
          32400
          8096
          3333
          6767
          7878
          7879
          8000
          8080
          8989
          8999
          9696
        ];
        extraCommands = ''
          iptables -w -A nixos-fw -p tcp -s 10.11.11.0/24 --dport 32400 -j nixos-fw-accept
          iptables -w -A nixos-fw -p tcp -s 10.11.11.0/24 --dport 8096 -j nixos-fw-accept
        '';
      };

      # The blanket doas rule keeps juggeli's whole environment, which would
      # point podman at the wrong HOME and storage and expose any exported
      # credentials to processes running as oci — the exact account a
      # container escape lands in. Last match wins in doas.conf, so this
      # narrower rule must sort after the blanket one; without keepEnv doas
      # resets HOME to oci's own, and only PATH (for the setuid newuidmap
      # wrapper) and the runtime dir need passing explicitly.
      security.doas.extraRules = lib.mkAfter [
        {
          users = [ "juggeli" ];
          runAs = "oci";
          noPass = true;
          setEnv = [
            "PATH=/run/wrappers/bin:/run/current-system/sw/bin"
            "XDG_RUNTIME_DIR=${ociRuntimeDir}"
          ];
        }
      ];

      # -C / because the caller's cwd may not be readable by oci.
      environment.shellAliases.podman-oci = "doas -u oci env -C / podman";

      # System units have no user session bus, so rootless podman cannot reach
      # the systemd cgroup manager and warns before falling back on every
      # invocation; pin the fallback to keep the logs quiet.
      virtualisation.containers.containersConf.settings.engine.cgroup_manager = "cgroupfs";

      systemd.tmpfiles.rules = [ "d ${ociRuntimeDir} 0700 oci media -" ];

      systemd.services = lib.mkMerge [
        # Rootless podman execs the setuid newuidmap/newgidmap wrappers, which
        # live outside the nix-store-only PATH the generated units get.
        (lib.genAttrs
          (map (name: "podman-${name}") (lib.attrNames config.virtualisation.oci-containers.containers))
          (_: {
            path = [ "/run/wrappers" ];
            environment.XDG_RUNTIME_DIR = ociRuntimeDir;
          })
        )
        (lib.genAttrs (map (name: "podman-${name}") mediaNetMembers) (_: {
          requires = [ "podman-media-network.service" ];
          after = [ "podman-media-network.service" ];
        }))
        {
          podman-media-network = {
            description = "Shared container network for the arr stack";
            wantedBy = [ "multi-user.target" ];
            path = [ "/run/wrappers" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              User = "oci";
              Environment = [
                "HOME=${config.users.users.oci.home}"
                "XDG_RUNTIME_DIR=${ociRuntimeDir}"
              ];
              ExecStart = "${pkgs.podman}/bin/podman network create --ignore --disable-dns --subnet=10.90.0.0/24 media";
            };
          };

          podman-qbittorrent.serviceConfig.ExecStartPre = [
            "${pkgs.coreutils}/bin/rm -f /mnt/appdata/qbittorrent/config/ipc-socket /mnt/appdata/qbittorrent/config/lockfile"
          ];

          # koto is first-party, so it follows the registry tag directly
          # instead of going through the soak. The soak's polkit rule already
          # lets the oci user restart podman-* units.
          koto-update = {
            description = "Update the koto container from its registry";
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            path = [
              pkgs.podman
              pkgs.systemd
              "/run/wrappers"
            ];
            serviceConfig = {
              Type = "oneshot";
              User = "oci";
              Environment = [
                "HOME=${config.users.users.oci.home}"
                "XDG_RUNTIME_DIR=${ociRuntimeDir}"
              ];
            };
            script = ''
              new=$(podman pull --quiet ghcr.io/juggeli/koto:latest)
              current=$(podman container inspect koto --format '{{.Image}}' 2>/dev/null || true)
              if [ "$new" != "$current" ] && systemctl is-active --quiet podman-koto.service; then
                systemctl restart podman-koto.service
              fi
            '';
          };
        }
      ];

      systemd.timers.koto-update = {
        timerConfig = {
          OnCalendar = "06:00";
          Persistent = true;
        };
        wantedBy = [ "timers.target" ];
      };

      boot.kernel.sysctl."net.ipv4.conf.all.src_valid_mark" = 1;

      services.recyclarr = {
        enable = true;
        configuration = {
          sonarr = {
            anime-sonarr-v4 = {
              base_url = "http://127.0.0.1:8999";
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
              base_url = "http://127.0.0.1:8989/";
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
