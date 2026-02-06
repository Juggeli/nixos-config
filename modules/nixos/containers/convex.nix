{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.containers.convex;

  serveConfig = pkgs.writeText "convex-tailscale-serve.json" (builtins.toJSON {
    TCP = {
      "443" = { HTTPS = true; };
      "3211" = { HTTPS = true; };
      "6791" = { HTTPS = true; };
    };
    Web = {
      "\${TS_CERT_DOMAIN}:443" = {
        Handlers."/" = { Proxy = "http://127.0.0.1:3210"; };
      };
      "\${TS_CERT_DOMAIN}:3211" = {
        Handlers."/" = { Proxy = "http://127.0.0.1:3211"; };
      };
      "\${TS_CERT_DOMAIN}:6791" = {
        Handlers."/" = { Proxy = "http://127.0.0.1:6791"; };
      };
    };
  });
in
{
  options.plusultra.containers.convex = with types; {
    enable = mkBoolOpt false "Whether or not to enable convex backend service.";
    dataDir = mkOption {
      type = str;
      default = "/mnt/appdata/convex";
      description = "Directory to store convex data.";
    };
    externalHost = mkOption {
      type = nullOr str;
      default = null;
      description = "External hostname for the backend. Required for external access.";
    };
    ports = {
      backend = mkOption {
        type = int;
        default = 3210;
        description = "Port for convex backend API.";
      };
      siteProxy = mkOption {
        type = int;
        default = 3211;
        description = "Port for convex site proxy (HTTP actions).";
      };
      dashboard = mkOption {
        type = int;
        default = 6791;
        description = "Port for convex dashboard.";
      };
    };
    tailscale = {
      enable = mkBoolOpt false "Whether to add a Tailscale sidecar container.";
      authKeyFile = mkOption {
        type = nullOr str;
        default = null;
        description = "Path to the Tailscale auth key file.";
      };
      hostname = mkOption {
        type = str;
        default = "convex";
        description = "Tailscale hostname for the sidecar.";
      };
    };
    homepage = {
      name = mkOption {
        type = str;
        default = "Convex";
        description = "Service name for homepage";
      };
      description = mkOption {
        type = str;
        default = "Reactive backend database";
        description = "Service description for homepage";
      };
      icon = mkOption {
        type = str;
        default = "convex.png";
        description = "Icon for homepage";
      };
      category = mkOption {
        type = str;
        default = "Development";
        description = "Category for homepage";
      };
      port = mkOption {
        type = int;
        default = 6791;
        description = "Port for homepage link (dashboard)";
      };
      url = mkOption {
        type = nullOr str;
        default = null;
        description = "Custom URL for homepage link (overrides auto-generated URL)";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.tailscale.enable -> cfg.tailscale.authKeyFile != null;
        message = "plusultra.containers.convex.tailscale.authKeyFile must be set when tailscale is enabled.";
      }
    ];

    virtualisation.oci-containers.containers = {
      tailscale-convex = mkIf cfg.tailscale.enable {
        image = "docker.io/tailscale/tailscale:latest";
        autoStart = true;
        environment = {
          TS_AUTHKEY = "file:/run/secrets/tailscale-authkey";
          TS_HOSTNAME = cfg.tailscale.hostname;
          TS_STATE_DIR = "/var/lib/tailscale";
          TS_SERVE_CONFIG = "/config/serve.json";
          TS_USERSPACE = "false";
        };
        volumes = [
          "${cfg.dataDir}/tailscale:/var/lib/tailscale"
          "${serveConfig}:/config/serve.json:ro"
          "${cfg.tailscale.authKeyFile}:/run/secrets/tailscale-authkey:ro"
        ];
        extraOptions = [
          "--cap-add=NET_ADMIN"
          "--cap-add=NET_RAW"
          "--device=/dev/net/tun:/dev/net/tun"
        ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };

      convex-backend = {
        image = "ghcr.io/get-convex/convex-backend:latest";
        autoStart = true;
        ports = mkIf (!cfg.tailscale.enable) [
          "${toString cfg.ports.backend}:3210"
          "${toString cfg.ports.siteProxy}:3211"
        ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
        volumes = [
          "${cfg.dataDir}:/convex/data"
        ];
        environment = {
          CONVEX_SITE_PROXY_PORT = "3211";
          ISOLATE_IDLE_TIMEOUT_SECONDS = "86400";
          ISOLATE_MAX_LIFETIME_SECONDS = "604800";
          DOCUMENT_RETENTION_DELAY = "172800";
        }
        // optionalAttrs (cfg.externalHost != null && cfg.tailscale.enable) {
          CONVEX_CLOUD_ORIGIN = "https://${cfg.externalHost}";
          CONVEX_SITE_ORIGIN = "https://${cfg.externalHost}:3211";
        }
        // optionalAttrs (cfg.externalHost != null && !cfg.tailscale.enable) {
          CONVEX_CLOUD_ORIGIN = "http://${cfg.externalHost}:${toString cfg.ports.backend}";
          CONVEX_SITE_ORIGIN = "http://${cfg.externalHost}:${toString cfg.ports.siteProxy}";
        };
        extraOptions = [
          "--health-cmd=curl -f http://localhost:3210/version || exit 1"
          "--health-interval=5s"
          "--health-timeout=5s"
          "--health-retries=3"
        ] ++ optionals cfg.tailscale.enable [
          "--network=container:tailscale-convex"
        ];
        dependsOn = mkIf cfg.tailscale.enable [ "tailscale-convex" ];
      };

      convex-dashboard = {
        image = "ghcr.io/get-convex/convex-dashboard:latest";
        autoStart = true;
        ports = mkIf (!cfg.tailscale.enable) [
          "${toString cfg.ports.dashboard}:6791"
        ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
        environment = {
          CONVEX_BACKEND_URL =
            if cfg.tailscale.enable
            then "http://127.0.0.1:3210"
            else "http://convex-backend:3210";
        };
        dependsOn =
          [ "convex-backend" ]
          ++ optionals cfg.tailscale.enable [ "tailscale-convex" ];
        extraOptions = optionals cfg.tailscale.enable [
          "--network=container:tailscale-convex"
        ];
      };
    };

    systemd.services = {
      podman-convex-backend = mkIf cfg.tailscale.enable {
        after = [ "podman-tailscale-convex.service" ];
      };
      podman-convex-dashboard.after =
        [ "podman-convex-backend.service" ]
        ++ optionals cfg.tailscale.enable [ "podman-tailscale-convex.service" ];
    };
  };
}
