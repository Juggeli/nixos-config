{ ... }:

{
  imports = [
    ./boot.nix
    ./graphical.nix
    ./syncthing.nix
    ./borgmatic.nix
    ./podman.nix
    ./flatpak.nix
    ./earlyoom.nix
    ./theming.nix
  ];
}
