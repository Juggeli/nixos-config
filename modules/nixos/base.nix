{ self, ... }:
{
  flake.nixosModules.base.imports = with self.nixosModules; [
    nix-settings
    users-juggeli
    home-manager
    boot
    zfs
    openssh
    tailscale
    agenix
    agenix-shared
    doas
    podman
    tools-misc
    hardware-storage
    system-fonts
    system-locale
    system-time
  ];
}
