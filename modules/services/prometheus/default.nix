{ options, config, pkgs, lib, ... }:

with lib;
with lib.internal;
let cfg = config.plusultra.services.prometheus;
in
{
  options.plusultra.services.prometheus = with types; {
    enable = mkBoolOpt false "Whether or not to enable prometheus service.";
  };

  config = mkIf cfg.enable { 
    environment.systemPackages = with pkgs; [
      plusultra.prometheus-smartctl
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
        ExecStart = "${pkgs.plusultra.prometheus-smartctl}/bin/smartprom";
      };
    };

    networking.firewall = {
      allowedTCPPorts = [ 9633 9090 9902 ];
    };
  };
}
