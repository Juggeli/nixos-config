{ config, lib, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.system.boot;
in
{
  options.plusultra.system.boot = with types; {
    enable = mkOption {
      default = true;
      type = with types; bool;
      description = "Enables booting via EFI";
    };
  };

  config = mkIf cfg.enable {
    boot = {
      loader = {
        efi = {
          canTouchEfiVariables = false;
        };
        grub = {
          enable = mkDefault true;
          device = "nodev";
          efiSupport = true;
          enableCryptodisk = mkDefault false;
          useOSProber = mkDefault false;
          efiInstallAsRemovable = true;
          memtest86.enable = true;
        };
      };
    };
  };
}
