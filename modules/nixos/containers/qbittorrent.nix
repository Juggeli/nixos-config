{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.containers.qbittorrent;
in
{
  options.plusultra.containers.qbittorrent = with types; {
    enable = mkBoolOpt false "Whether or not to enable qbittorrent service.";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.qbittorrent = {
      image = "ghcr.io/hotio/qbittorrent";
      autoStart = true;
      ports = [ "8080:8080" ];
      volumes = [
        "/var/lib/qbittorrent:/config"
        "/mnt/pool/:/mnt/pool/"
      ];
      environment = {
        VPN_ENABLED = "true";
        VPN_PROVIDER = "proton";
        VPN_LAN_NETWORK = "100.64.0.0/10";
        VPN_CONF = "wg0";
        VPN_AUTO_PORT_FORWARD = "true";
        VPN_KEEP_LOCAL_DNS = "false";
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

    environment.systemPackages = with pkgs; [
      plusultra.qbit-manager
    ];

    systemd.services.qbit-manager = {
      description = "manage qbittorrent";
      serviceConfig = {
        User = "juggeli";
        Type = "oneshot";
      };
      script = ''
        ${pkgs.plusultra.qbit-manager}/bin/qbit-manager
      '';
    };
    systemd.timers.qbit-manager = {
      wantedBy = [ "timers.target" ];
      after = [ "podman-qbittorrent.service" ];
      partOf = [ "qbit-manager.service" ];
      timerConfig = {
        OnUnitActiveSec = "30s";
        OnBootSec = "300s";
        Unit = "qbit-manager.service";
      };
    };
    
    # Add to homepage
    plusultra.services.homepage.services = mkIf config.plusultra.services.homepage.enable {
      Media = [{
        qBittorrent = {
          href = "http://${config.networking.hostName}:8080";
          icon = "qbittorrent.png";
        };
      }];
    };
  };
}
