{ ... }:

{
  imports = [
    ./avahi.nix
    ./cloudflared.nix
    ./cockpit.nix
    ./grafana.nix
    ./homepage.nix
    ./log-analyzer.nix
    ./markdown-viewer.nix
    ./kdeconnect.nix
    ./nfs.nix
    ./openssh.nix
    ./printing.nix
    ./prometheus.nix
    ./qbittorrent-manager.nix
    ./samba.nix
    ./tailscale.nix
  ];
}
