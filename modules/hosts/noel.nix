{ self, ... }:
{
  flake.nixosConfigurations.noel = self.lib.mkNixos {
    system = "x86_64-linux";
    hostName = "noel";
    modules = with self.nixosModules; [
      nix-settings
      users-juggeli
      networking
      boot
      zfs
      impermanence
      tmpfs
      openssh
      tailscale
      agenix
      doas
      podman
      tools-misc
      hardware-audio
      hardware-storage
      system-fonts
      system-locale
      system-time
      services-printing
      ../../hosts/noel
    ];
  };
}
