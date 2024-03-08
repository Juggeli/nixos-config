{ ... }:

{
  imports = [
    ./btrfs.nix
    ./encryption.nix
    ./impermanence.nix
    ./tmpfs.nix
    ./zfs.nix
  ];
}
