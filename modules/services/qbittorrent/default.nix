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
          "/mnt/appdata/qbittorrent2:/config"
          "/mnt/pool/downloads/:/mnt/pool/downloads/"
          "/mnt/pool/media/:/mnt/pool/media/"
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

    # environment.systemPackages = with pkgs; [ qbittorrent-nox ];
    #
    # plusultra.home.extraOptions = { config, pkgs, ... }: {
    #   home.file.".local/share/qBittorrent".source = config.lib.file.mkOutOfStoreSymlink "/mnt/appdata/qbittorrent";
    #   home.file.".config/qBittorrent".source = config.lib.file.mkOutOfStoreSymlink "/mnt/appdata/qbittorrent";
    # };
    #
    # systemd = {
    #   packages = [ pkgs.qbittorrent-nox ];
    #
    #   services."qbittorrent-nox@juggeli" = {
    #     enable = true;
    #     serviceConfig = {
    #       Type = "simple";
    #       User = "juggeli";
    #       ExecStart = "${pkgs.qbittorrent-nox}/bin/qbittorrent-nox";
    #     };
    #     wantedBy = [ "multi-user.target" ];
    #   };
    # };

    networking.firewall.allowedTCPPorts = [ 8081 ];
  };
}
