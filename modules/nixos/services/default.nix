{ ... }:

{
  imports = [
    ./avahi.nix
    ./cloudflared.nix
    ./cockpit.nix
    ./grafana.nix
    ./homepage.nix
    ./kdeconnect.nix
    ./nfs.nix
    ./openssh.nix
    ./printing.nix
    ./prometheus.nix
    ./remote-downloader.nix
    ./samba.nix
    ./tailscale.nix
  ];
}
