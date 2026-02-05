{
  config,
  lib,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.containers.convex;
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
      description = "External hostname for the backend (e.g., haruka.tailac5b0.ts.net). Required for external access.";
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
    virtualisation.oci-containers.containers.convex-backend = {
      image = "ghcr.io/get-convex/convex-backend:latest";
      autoStart = true;
      ports = [
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
      }
      // optionalAttrs (cfg.externalHost != null) {
        CONVEX_CLOUD_ORIGIN = "http://${cfg.externalHost}:${toString cfg.ports.backend}";
        CONVEX_SITE_ORIGIN = "http://${cfg.externalHost}:${toString cfg.ports.siteProxy}";
      };
      extraOptions = [
        "--health-cmd=curl -f http://localhost:3210/version || exit 1"
        "--health-interval=5s"
        "--health-timeout=5s"
        "--health-retries=3"
      ];
    };

    virtualisation.oci-containers.containers.convex-dashboard = {
      image = "ghcr.io/get-convex/convex-dashboard:latest";
      autoStart = true;
      ports = [
        "${toString cfg.ports.dashboard}:6791"
      ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
      environment = {
        CONVEX_BACKEND_URL = "http://convex-backend:3210";
      };
      dependsOn = [ "convex-backend" ];
    };

    systemd.services.podman-convex-dashboard.after = [ "podman-convex-backend.service" ];
  };
}
