{ options, config, pkgs, lib, ... }:
with lib;
with lib.my;
let
  cfg = config.modules.services.prometheus;
in
{
  options.modules.services.prometheus = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.my.prometheus-smartctl
    ];

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
      };

      scrapeConfigs = [{
        job_name = "prometheus";
        static_configs = [{
          targets = [
            "127.0.0.1:${toString config.services.prometheus.exporters.node.port}"
            "127.0.0.1:${toString config.services.prometheus.exporters.smokeping.port}"
            "127.0.0.1:9902"
          ];
        }];
      }];
    };
    systemd.services."smartprom" = {
      description = "monitor smart devices";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        DeviceAllow = lib.mkOverride 10 [
          "block-blkext rw"
          "block-sd rw"
          "char-nvme rw"
        ];
        ExecStart = "${pkgs.my.prometheus-smartctl}/bin/smartprom";
      };
    };

    networking.firewall = {
      allowedTCPPorts = [ 9633 9090 9902 ];
    };
  };
}
