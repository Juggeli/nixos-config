{
  flake.nixosModules.flatpak = {
    services.flatpak.enable = true;

    environment.persistence."/persist".directories = [
      "/var/lib/flatpak"
    ];
  };
}
