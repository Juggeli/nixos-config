{
  flake.nixosModules.hardware-logitech = {
    hardware.logitech.wireless = {
      enable = true;
      enableGraphical = true;
    };
  };
}
