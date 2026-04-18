{
  flake.nixosModules.boot =
    { lib, ... }:
    {
      boot.loader = {
        efi.canTouchEfiVariables = false;
        grub = {
          enable = lib.mkDefault true;
          device = "nodev";
          efiSupport = true;
          enableCryptodisk = lib.mkDefault false;
          useOSProber = lib.mkDefault false;
          efiInstallAsRemovable = true;
          memtest86.enable = true;
        };
      };
    };
}
