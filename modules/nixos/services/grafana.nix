{ config, lib, ... }:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.services.grafana;
in
{
  options.plusultra.services.grafana = with types; {
    enable = mkBoolOpt false "Whether or not to enable grafana service.";
  };

  config = mkIf cfg.enable {
    services.grafana = {
      enable = true;
      dataDir = "/mnt/appdata/grafana/";
      settings.server = {
        http_port = 3000;
        http_addr = "10.11.11.2";
      };
    };

    networking.firewall = {
      allowedTCPPorts = [ config.services.grafana.settings.server.http_port ];
    };
  };
}
