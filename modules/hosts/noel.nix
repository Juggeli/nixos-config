{ self, ... }:
{
  flake.nixosConfigurations.noel = self.lib.mkNixos {
    system = "x86_64-linux";
    hostName = "noel";
    modules = with self.nixosModules; [
      nix-settings
      users-juggeli
      home-manager
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
      hardware-logitech
      system-fonts
      system-locale
      system-time
      services-printing
      theming
      graphical
      hyprland
      hyprlock
      hypridle
      wlsunset
      logitech-mouse-resume
      desktop-gtk
      desktop-qt
      desktop-mako
      desktop-rofi
      desktop-electron
      onepassword
      avahi
      flatpak
      ../../hosts/noel
    ];
  };
}
