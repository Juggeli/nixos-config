{ options, config, lib, ... }:

with lib;
with lib.my;
let cfg = config.modules.services.grafana;
in
{
  options.modules.services.grafana = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.grafana = {
      enable = true;
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
