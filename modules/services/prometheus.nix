{ options, config, lib, ... }:
with lib;
with lib.my;
let cfg = config.modules.services.prometheus;
in {
  options.modules.services.prometheus = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.prometheus = {
      enable = true;

      exporters = {
        node = {
          enable = true;
        };

        smokeping = {
          enable = true;
          hosts = [ "1.1.1.1" "google.com" ];
        };

        smartctl = {
          enable = true;
        };
      };

      scrapeConfigs = [{
        job_name = "prometheus";
        static_configs = [{
          targets = [
            "127.0.0.1:${toString config.services.prometheus.exporters.node.port}"
              "127.0.0.1:${toString config.services.prometheus.exporters.smokeping.port}"
              "127.0.0.1:${toString config.services.prometheus.exporters.smartctl.port}"
          ];
        }];
      }];
    };
    systemd.services."prometheus-smartctl-exporter".serviceConfig.DeviceAllow = lib.mkOverride 10 [
      "block-blkext rw"
        "block-sd rw"
        "char-nvme rw"
    ];
  };
}
