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
    ./samba.nix
    ./tailscale.nix
  ];
}
