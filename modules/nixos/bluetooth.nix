{
  flake.nixosModules.bluetooth = {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      # The GuliKit controller pairs without storing a bond, so its reconnects
      # arrive unbonded; bluez rejects those by default since 5.71
      input.General.ClassicBondedOnly = false;
    };
  };
}
