{ options, config, pkgs, lib, ... }:

with lib;
with lib.internal;
let cfg = config.plusultra.hardware.logitech;
in
{
  options.plusultra.hardware.logitech = with types; {
    enable = mkBoolOpt false "Whether or not to enable logitech support";
  };

  config = mkIf cfg.enable {
    hardware.logitech.wireless = {
      enable = true;
      enableGraphical = true;
    };
  };
}
