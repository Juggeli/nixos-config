{ modulesPath, lib, ... }:

with lib;
with lib.plusultra; {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
  ];

  plusultra = {
    suites = {
      common-slim = enabled;
    };
    services = {
      openssh.authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMMRlC0Hzv2D+8e0m1/XT27b7RaMLm9wX16bz6TJPKdt jukka"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBpvXZ6hWXrKgvX1ce+v+tmjYO2EuW9YjS8o5N7vmfRO juggeli@gmail.com"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICbJeg8M8Pmbab+/X5on+hFEJlLW0/f4vX8nNtDNAcox jukka"
      ];
    };
  };

  system.stateVersion = "23.11";
}
