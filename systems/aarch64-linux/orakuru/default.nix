{ pkgs, config, lib, channel, ... }:

with lib;
with lib.internal;
{
  imports = [
    ./hardware.nix
  ];

  plusultra = {
    archetypes = {
      server = enabled;
    };
    services = {
      openssh.authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMMRlC0Hzv2D+8e0m1/XT27b7RaMLm9wX16bz6TJPKdt jukka"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBpvXZ6hWXrKgvX1ce+v+tmjYO2EuW9YjS8o5N7vmfRO juggeli@gmail.com"
      ];
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
