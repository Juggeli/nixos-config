{
  flake.nixosModules.hardware-storage =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        ntfs3g
        fuseiso
        btrfs-progs
      ];
    };
}
