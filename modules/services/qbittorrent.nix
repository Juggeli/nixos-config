{ options, config, pkgs, lib, ... }:
with lib;
with lib.my;
let cfg = config.modules.services.qbittorrent;
in
{
  options.modules.services.qbittorrent = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ qbittorrent-nox ];

    hm = { config, pkgs, ... }: {
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

