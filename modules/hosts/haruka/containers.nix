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
        silverbullet = "ghcr.io/silverbulletmd/silverbullet:latest";
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

      silverbulletServeConfig = pkgs.writeText "silverbullet-tailscale-serve.json" (
        builtins.toJSON {
          TCP = {
            "443" = {
              HTTPS = true;
            };
          };
          Web = {
            "\${TS_CERT_DOMAIN}:443" = {
              Handlers."/" = {
                Proxy = "http://127.0.0.1:3000";
              };
            };
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

        tailscale-notes = soaked "tailscale" // {
          autoStart = true;
          environment = {
            TS_AUTHKEY = "file:/run/secrets/tailscale-authkey";
            TS_HOSTNAME = "notes";
            TS_STATE_DIR = "/var/lib/tailscale";
            TS_SERVE_CONFIG = "/config/serve.json";
            # Userspace netstack for the same reason as tailscale-koto: serve
            # terminates tailnet TLS and proxies over the shared loopback, so
            # no tun device or network capability is needed.
            TS_USERSPACE = "true";
          };
          volumes = [
            "/mnt/appdata/silverbullet/tailscale:/var/lib/tailscale"
            "${silverbulletServeConfig}:/config/serve.json:ro"
            "${config.age.secrets.tailscale-auth.path}:/run/secrets/tailscale-authkey:ro"
          ];
          extraOptions = hardened;
        };

        silverbullet = soaked "silverbullet" // {
          autoStart = true;
          # Shares the sidecar's network namespace, so the web UI is only
          # reachable as https://notes.<tailnet>.ts.net — serve provides the
          # HTTPS that the offline PWA's service worker requires.
          extraOptions = hardened ++ [ "--network=container:tailscale-notes" ];
          # The image runs as whatever uid owns /space — container root here,
          # which rootless podman maps back onto oci — so no keep-id mapping
          # is needed.
          #
          # The env file carries SB_USER (web login) and SB_AUTH_TOKEN (bearer
          # token for the HTTP API). Shell command execution stays off: notes
          # do not need it, and it would hand an exec primitive to anything
          # holding the token.
          environment = {
            SB_SHELL_BACKEND = "off";
            # The login lives behind the tailnet already, so a "remember me"
            # session can outlast the 7-day default; a year keeps the phone
            # PWA from asking again.
            SB_REMEMBER_ME_HOURS = "8760";
          };
          environmentFiles = [ config.age.secrets.silverbullet-env.path ];
          volumes = [ "/mnt/appdata/silverbullet/space:/space" ];
          dependsOn = [ "tailscale-notes" ];
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
        silverbullet-env.owner = "oci";
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

      systemd.tmpfiles.rules = [
        "d ${ociRuntimeDir} 0700 oci media -"
        # The tailscale sidecar state lives beside the space, not inside it,
        # so it never shows up as pages.
        "d /mnt/appdata/silverbullet 0750 oci media -"
        "d /mnt/appdata/silverbullet/space 0750 oci media -"
        "d /mnt/appdata/silverbullet/tailscale 0750 oci media -"
        # Koto's appdata is edited from the host as juggeli, which leaves files
        # the oci-mapped container cannot write; its task runner swallows the
        # EACCES, so the breakage is silent. Repair ownership on every
        # activation, and default ACLs make files created between activations
        # group-writable at birth (default ACLs bypass the creator's umask).
        "Z /mnt/appdata/koto - oci media -"
        "A+ /mnt/appdata/koto - - - - g:media:rwX,d:g:media:rwX"
      ];

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

              quality_definition.type = "anime";

              quality_profiles = [
                {
                  # Guide-managed profile; recyclarr syncs the anime custom
                  # formats and their scores from this trash_id.
                  trash_id = "20e0fc959f1f1704bed501f23bdae76f"; # [Anime] Remux-1080p
                  name = "Remux-1080p - Anime";
                  reset_unmatched_scores.enabled = true;
                  # Bluray-1080p sits above the WEB group so the BD upgrade is
                  # a quality upgrade; remuxes stay excluded from the ladder.
                  upgrade = {
                    allowed = true;
                    until_quality = "Bluray-1080p";
                    until_score = 10000;
                  };
                  min_format_score = 100;
                  # Blocks same-quality group swaps (tier differences are a few
                  # hundred points); only Uncensored (+2000) passes.
                  min_upgrade_format_score = 1000;
                  quality_sort = "top";
                  qualities = [
                    { name = "Bluray-1080p"; }
                    {
                      name = "WEB 1080p";
                      qualities = [
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
                  # Uncensored releases always win and upgrade over censored.
                  trash_ids = [ "026d5aadd1a6b4e550b134cb6c72b3ca" ]; # Uncensored
                  assign_scores_to = [
                    {
                      name = "Remux-1080p - Anime";
                      score = 2000;
                    }
                  ];
                }
                {
                  trash_ids = [ "b2550eb333d27b75833e25b8c2557b38" ]; # 10bit
                  assign_scores_to = [
                    {
                      name = "Remux-1080p - Anime";
                      score = 10;
                    }
                  ];
                }
                {
                  # Untouched CR rips (SubsPlease & co): the only web tier that
                  # reaches min_format_score, so ongoing episodes always come
                  # from the same stable source instead of racing muxer groups.
                  trash_ids = [ "29c2a13d091144f63307e4a8ce963a39" ]; # Anime Web Tier 05
                  assign_scores_to = [
                    {
                      name = "Remux-1080p - Anime";
                      score = 100;
                    }
                  ];
                }
                {
                  # Muxer/fansub web tiers: kept below min_format_score.
                  trash_ids = [
                    "e0014372773c8f0e1bef8824f00c7dc4" # Anime Web Tier 01
                    "19180499de5ef2b84b6ec59aae444696" # Anime Web Tier 02
                    "c27f2ae6a4e82373b0f1da094e2489ad" # Anime Web Tier 03
                    "4fd5528a3a8024e6b49f9c67053ea5f3" # Anime Web Tier 04
                    "dc262f88d74c651b12e9d90b39f6c753" # Anime Web Tier 06
                  ];
                  assign_scores_to = [
                    {
                      name = "Remux-1080p - Anime";
                      score = 0;
                    }
                  ];
                }
              ];
            };

            web-2160p-v4 = {
              base_url = "http://127.0.0.1:8989/";
              api_key._secret = config.age.secrets.sonarr-api.path;

              quality_definition.type = "series";

              quality_profiles = [
                {
                  trash_id = "d1498e7d189fbe6c7110ceaabb7473e6"; # WEB-2160p
                  name = "WEB-2160p";
                  reset_unmatched_scores.enabled = true;
                  # Blocks same-quality release-group swaps (tier differences
                  # are ~100 points); the 1080p -> 2160p quality upgrade is
                  # unaffected.
                  min_upgrade_format_score = 400;
                  # The guide ladder is 2160p-only; keep WEB 1080p allowed as a
                  # fallback when no 2160p release exists.
                  upgrade = {
                    allowed = true;
                    until_quality = "WEB 2160p";
                    until_score = 10000;
                  };
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
                {
                  # For series deliberately kept at 1080p to save space.
                  trash_id = "72dae194fc92bf828f32cde7744e51a1"; # WEB-1080p
                  name = "WEB-1080p";
                  reset_unmatched_scores.enabled = true;
                  min_upgrade_format_score = 400;
                  # 720p rungs below the guide's WEB 1080p cutoff so series
                  # with no 1080p release still grab and upgrade later.
                  upgrade = {
                    allowed = true;
                    until_quality = "WEB 1080p";
                    until_score = 10000;
                  };
                  qualities = [
                    {
                      name = "WEB 1080p";
                      qualities = [
                        "WEBDL-1080p"
                        "WEBRip-1080p"
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
                  ];
                }
              ];

              # Default groups (HDR, Streaming General, Unwanted, Golden Rule
              # UHD, HD/UHD boost, Language Profiles) sync automatically; these
              # entries only opt into non-default formats.
              custom_format_groups.add = [
                {
                  trash_id = "59c3af66780d08332fdc64e68297098f"; # [Unwanted] Unwanted Formats
                  select = [
                    "82d40da2bc6923f41e14394075dd4b03" # No-RlsGroup
                    "e1a997ddb54e3ecbfe06341ad323c458" # Obfuscated
                    "06d66ab109d4d2eddb2794d21526d140" # Retags
                  ];
                }
                {
                  trash_id = "d776a1ea912a117d66d83b880ff2055d"; # [HDR Formats] DV (w/o HDR fallback)
                }
                {
                  trash_id = "e1053c0ef622df3749fa43c22865663a"; # [Optional] SDR
                  select = [ "83304f261cf516bb208c18c54c0adf97" ]; # SDR (no WEBDL)
                }
              ];
            };
          };

          radarr = {
            anime-radarr-v5 = {
              base_url = "http://127.0.0.1:7879";
              api_key._secret = config.age.secrets.radarr-anime-api.path;

              quality_definition.type = "anime";

              quality_profiles = [
                {
                  # Guide-managed profile; movies are one-off grabs so the
                  # guide's BD/web tier scores stay as-is (the per-episode
                  # group-stability concern from sonarr-anime doesn't apply).
                  trash_id = "722b624f9af1e492284c4bc842153a38"; # [Anime] Remux-1080p
                  name = "Remux-1080p - Anime";
                  reset_unmatched_scores.enabled = true;
                  # 2160p rungs extend the guide's 1080p ladder so movies with a
                  # real 4K HDR release upgrade to it (SDR 2160p is rejected via
                  # custom format, so only genuine HDR makes the jump); remuxes
                  # stay excluded entirely.
                  upgrade = {
                    allowed = true;
                    until_quality = "Bluray-2160p";
                    until_score = 10000;
                  };
                  # Blocks same-quality group swaps (tier differences are a few
                  # hundred points); only Uncensored (+2000) passes.
                  min_upgrade_format_score = 1000;
                  quality_sort = "top";
                  qualities = [
                    { name = "Bluray-2160p"; }
                    {
                      name = "WEB 2160p";
                      qualities = [
                        "WEBDL-2160p"
                        "WEBRip-2160p"
                      ];
                    }
                    { name = "Bluray-1080p"; }
                    {
                      name = "WEB 1080p";
                      qualities = [
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
                    { name = "Bluray-576p"; }
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
                  # Uncensored releases always win and upgrade over censored.
                  trash_ids = [ "064af5f084a0a24458cc8ecd3220f93f" ]; # Uncensored
                  assign_scores_to = [
                    {
                      name = "Remux-1080p - Anime";
                      score = 2000;
                    }
                  ];
                }
                {
                  # Matches every HDR flavor incl. DV with HDR10 fallback; also
                  # lets 4K HDR rips from groups outside the anime tiers pass
                  # the profile's min format score of 100.
                  trash_ids = [ "493b6d1dbec3c3364c59d7607f7e3405" ]; # HDR
                  assign_scores_to = [
                    {
                      name = "Remux-1080p - Anime";
                      score = 500;
                    }
                  ];
                }
                {
                  # SDR only matches 2160p releases: 1080p grabs are unaffected
                  # and the 4K rung is reserved for real HDR. DV without an HDR
                  # fallback plays wrong on non-DV displays.
                  trash_ids = [
                    "9c38ebb7384dada637be8899efa68e6f" # SDR
                    "923b6abef9b17f937fab56cfcf89e1f1" # DV (w/o HDR fallback)
                  ];
                  assign_scores_to = [
                    {
                      name = "Remux-1080p - Anime";
                      score = -10000;
                    }
                  ];
                }
                # Lossless/Atmos audio at the guide's UHD scores; lossy formats
                # stay unscored so everyday web grabs are unaffected.
                {
                  trash_ids = [ "496f355514737f7d83bf7aa4d24f8169" ]; # TrueHD ATMOS
                  assign_scores_to = [
                    {
                      name = "Remux-1080p - Anime";
                      score = 5000;
                    }
                  ];
                }
                {
                  trash_ids = [ "2f22d89048b01681dde8afe203bf2e95" ]; # DTS X
                  assign_scores_to = [
                    {
                      name = "Remux-1080p - Anime";
                      score = 4500;
                    }
                  ];
                }
                {
                  trash_ids = [
                    "1af239278386be2919e1bcee0bde047e" # DD+ ATMOS
                    "417804f7f2c4308c1f4c5d380d4c4475" # ATMOS (undefined)
                  ];
                  assign_scores_to = [
                    {
                      name = "Remux-1080p - Anime";
                      score = 3000;
                    }
                  ];
                }
                {
                  trash_ids = [ "3cafb66171b47f226146a0770576870f" ]; # TrueHD
                  assign_scores_to = [
                    {
                      name = "Remux-1080p - Anime";
                      score = 2750;
                    }
                  ];
                }
                {
                  trash_ids = [ "dcf3ec6938fa32445f590a4da84256cd" ]; # DTS-HD MA
                  assign_scores_to = [
                    {
                      name = "Remux-1080p - Anime";
                      score = 2500;
                    }
                  ];
                }
                {
                  trash_ids = [
                    "a570d4a0e56a2874b64e5bfa55202a1b" # FLAC
                    "e7c2fcae07cbada050a0af3357491d7b" # PCM
                  ];
                  assign_scores_to = [
                    {
                      name = "Remux-1080p - Anime";
                      score = 2250;
                    }
                  ];
                }
                {
                  trash_ids = [ "8e109e50e0a0b83a5098b056e13bf6db" ]; # DTS-HD HRA
                  assign_scores_to = [
                    {
                      name = "Remux-1080p - Anime";
                      score = 2000;
                    }
                  ];
                }
              ];
            };

            movies-radarr-v5 = {
              base_url = "http://127.0.0.1:7878";
              api_key._secret = config.age.secrets.radarr-api.path;

              quality_definition.type = "movie";

              quality_profiles = [
                {
                  trash_id = "64fb5f9858489bdac2af690e27c8f42f"; # UHD Bluray + WEB
                  name = "UHD Bluray + WEB";
                  reset_unmatched_scores.enabled = true;
                  # Blocks same-quality release-group swaps (tier differences
                  # are ~100 points); quality upgrades are unaffected.
                  min_upgrade_format_score = 400;
                  upgrade = {
                    allowed = true;
                    until_quality = "Bluray-2160p";
                    until_score = 10000;
                  };
                  # The guide ladder is 2160p-only; keep 1080p/720p rungs as
                  # fallbacks when no 2160p release exists.
                  qualities = [
                    { name = "Bluray-2160p"; }
                    {
                      name = "WEB 2160p";
                      qualities = [
                        "WEBDL-2160p"
                        "WEBRip-2160p"
                      ];
                    }
                    { name = "Bluray-1080p"; }
                    {
                      name = "WEB 1080p";
                      qualities = [
                        "WEBDL-1080p"
                        "WEBRip-1080p"
                      ];
                    }
                    { name = "Bluray-720p"; }
                  ];
                }
              ];

              # Default groups (HDR, Streaming General, Unwanted, Golden Rule,
              # Audio Formats, Repack/Proper) sync automatically; these entries
              # only opt into non-default formats.
              custom_format_groups.add = [
                {
                  trash_id = "a3ac6af01d78e4f21fcb75f601ac96df"; # [Unwanted] Unwanted Formats
                  select = [
                    "ae9b7c9ebde1f3bd336a8cbd1ec4c5e5" # No-RlsGroup
                    "7357cf5161efbf8c4d5d0c30b4815ee2" # Obfuscated
                    "5c44f52a8714fdd79bb4d98e2673be1f" # Retags
                    "f537cf427b64c38c8e36298f657e4828" # Scene
                  ];
                }
                {
                  trash_id = "7fc2751eef7e6bdc70b74136e5e35c76"; # [HDR Formats] DV (w/o HDR fallback)
                }
                {
                  # Full SDR block: 2160p SDR releases are never wanted.
                  trash_id = "47f0d69750de9e16855915fa73bb7b08"; # [HDR Formats] SDR
                  select = [ "9c38ebb7384dada637be8899efa68e6f" ]; # SDR
                }
                {
                  trash_id = "f4f1474b963b24cf983455743aa9906c"; # [Optional] Movie Versions
                  select = [
                    "eca37840c13c6ef2dd0262b141a5482f" # 4K Remaster
                    "e0c07d59beb37348e975a930d5e50319" # Criterion Collection
                    "eecf3a857724171f968a66cb5719e152" # IMAX
                    "9f6cbff8cfe4ebbc1bde14c7b7bec0de" # IMAX Enhanced
                    "9d27d9d2181838f76dee150882bdc58c" # Masters of Cinema
                    "570bc9ebecd92723d2d21500f4be314c" # Remaster
                    "957d0f44b592285f26449575e8b1167e" # Special Edition
                    "db9b4c4b53d312a3ca5f1378f6440fc9" # Vinegar Syndrome
                  ];
                }
              ];
            };
          };
        };
      };
    };
}
