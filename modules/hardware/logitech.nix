{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let 
  cfg = config.modules.hardware.logitech;
in {
  options.modules.hardware.logitech = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hardware.logitech.wireless = {
      enable = true;
      enableGraphical = true;
    };
  };
}
