{ options, config, pkgs, lib, ... }:

with lib;
with lib.internal;
let cfg = config.plusultra.services.qbittorrent;
in
{
  options.plusultra.services.qbittorrent = with types; {
    enable = mkBoolOpt false "Whether or not to enable qbittorrent service.";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.backend = "podman";
    virtualisation.oci-containers.containers = {
      qbittorrent = {
        image = "dyonr/qbittorrentvpn:latest";
        autoStart = true;
        ports = [ "8080:8080" ];
        volumes = [
          "/mnt/appdata/qbittorrent:/config"
          "/mnt/pool/downloads/:/mnt/pool/downloads/"
          "/mnt/pool/media/:/mnt/pool/media/"
          "${pkgs.plusultra.qbittorrent-dracula}/webui/:/webui"
        ];
        environment = {
          VPN_ENABLED = "yes";
          VPN_TYPE = "wireguard";
          LAN_NETWORK = "10.11.11.0/24";
          PUID = "1000";
          PGID = "100";
        };
        extraOptions = [
          "--cap-add=NET_ADMIN"
        ];
      };
    };
  };
}
