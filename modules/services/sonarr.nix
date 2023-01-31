{ options, config, pkgs, lib, ... }:
with lib;
with lib.my;
let cfg = config.modules.services.sonarr;
in
{
  options.modules.services.sonarr = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.sonarr = {
      enable = true;
      openFirewall = true;
      dataDir = "/mnt/appdata/sonarr";
    };

    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      virtualHosts."sonarr.jugi.cc" = {
        forceSSL = true;
        enableACME = true;
        basicAuth = { sonarr = "4.Y3iiu6CZxrdgyCaFd349Cy"; };
        extraConfig = ''
          proxy_buffering off;
        '';
        locations."/" = {
          proxyPass = "http://127.0.0.1:8989";
          proxyWebsockets = true;
        };
      };
    };
  };
}


