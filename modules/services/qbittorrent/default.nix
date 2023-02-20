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
    environment.systemPackages = with pkgs; [ qbittorrent-nox ];

    plusultra.home.extraOptions = { config, pkgs, ... }: {
      home.file.".local/share/qBittorrent".source = config.lib.file.mkOutOfStoreSymlink "/mnt/appdata/qbittorrent";
      home.file.".config/qBittorrent".source = config.lib.file.mkOutOfStoreSymlink "/mnt/appdata/qbittorrent";
    };

    systemd = {
      packages = [ pkgs.qbittorrent-nox ];

      services."qbittorrent-nox@juggeli" = {
        enable = true;
        serviceConfig = {
          Type = "simple";
          User = "juggeli";
          ExecStart = "${pkgs.qbittorrent-nox}/bin/qbittorrent-nox";
        };
        wantedBy = [ "multi-user.target" ];
      };
    };

    networking.firewall.allowedTCPPorts = [ 8081 17637 ];
  };
}
