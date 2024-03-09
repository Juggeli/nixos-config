{ ... }:

{
  imports = [
    ./avahi.nix
    ./cloudflared.nix
    ./cockpit.nix
    ./grafana.nix
    ./nfs.nix
    ./openssh.nix
    ./printing.nix
    ./prometheus.nix
    ./samba.nix
    ./tailscale.nix
  ];
}
