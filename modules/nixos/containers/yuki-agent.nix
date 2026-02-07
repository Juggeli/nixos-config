{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.containers.yuki-agent;

  configFile = pkgs.writeText "config.jsonc" (builtins.toJSON cfg.settings);

  serveConfig = pkgs.writeText "yuki-agent-tailscale-serve.json" (
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
  options.plusultra.containers.yuki-agent = with types; {
    enable = mkBoolOpt false "Whether or not to enable yuki-agent.";
    environmentFile = mkOption {
      type = nullOr path;
      default = null;
      description = "Path to environment file containing API keys.";
    };
    settings = mkOption {
      type = attrs;
      default = { };
      description = "Yuki Agent configuration (serialized to config.jsonc).";
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
        default = "yuki-agent";
        description = "Tailscale hostname for the sidecar.";
      };
    };
    homepage = {
      name = mkOption {
        type = str;
        default = "Yuki Agent";
        description = "Service name for homepage";
      };
      description = mkOption {
        type = str;
        default = "Personal AI assistant";
        description = "Service description for homepage";
      };
      icon = mkOption {
        type = str;
        default = "robot.png";
        description = "Icon for homepage";
      };
      category = mkOption {
        type = str;
        default = "Other";
        description = "Category for homepage";
      };
      port = mkOption {
        type = int;
        default = 9847;
        description = "Port for homepage link";
      };
      url = mkOption {
        type = nullOr str;
        default = null;
        description = "Custom URL for homepage link (overrides auto-generated URL)";
      };
      widget = {
        enable = mkOption {
          type = bool;
          default = false;
          description = "Enable API widget for homepage";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.tailscale.enable -> cfg.tailscale.authKeyFile != null;
        message = "plusultra.containers.yuki-agent.tailscale.authKeyFile must be set when tailscale is enabled.";
      }
    ];

    virtualisation.oci-containers.containers = {
      tailscale-yuki-agent = mkIf cfg.tailscale.enable {
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
          "/mnt/appdata/yuki-agent/tailscale:/var/lib/tailscale"
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

      yuki-agent = {
        image = "ghcr.io/juggeli/yuki-agent:latest";
        autoStart = true;
        extraOptions =
          if cfg.tailscale.enable then
            [ "--network=container:tailscale-yuki-agent" ]
          else
            [ "--network=host" ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
        volumes = [
          "/mnt/appdata/agents:/mnt/appdata/agents"
          "${configFile}:/app/config.jsonc:ro"
        ];
        environmentFiles = mkIf (cfg.environmentFile != null) [ cfg.environmentFile ];
        dependsOn = optionals cfg.tailscale.enable [ "tailscale-yuki-agent" ];
      };
    };

    systemd.services = mkIf cfg.tailscale.enable {
      podman-yuki-agent.after = [ "podman-tailscale-yuki-agent.service" ];
    };
  };
}
