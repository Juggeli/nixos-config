{ config, lib, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.services.qbittorrent;
in
{
  options.plusultra.services.qbittorrent = with types; {
    enable = mkBoolOpt false "Whether or not to enable qbittorrent service.";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.qbittorrent = {
      image = "ghcr.io/hotio/qbittorrent";
      autoStart = true;
      ports = [ "8080:8080" ];
      volumes = [
        "/mnt/appdata/qbittorrent:/config"
        "/mnt/pool/:/mnt/pool/"
      ];
      environment = {
        VPN_ENABLED = "true";
        VPN_LAN_NETWORK = "100.64.0.0/10";
        VPN_CONF = "wg0";
        PRIVOXY_ENABLED = "false";
        PUID = "1000";
        PGID = "100";
      };
      extraOptions = [
        "--cap-add=NET_ADMIN"
        "--cap-add=NET_RAW"
        ''--sysctl="net.ipv6.conf.all.disable_ipv6=1"''
      ];
    };
    boot.kernel.sysctl."net.ipv4.conf.all.src_valid_mark" = 1;
  };
}
