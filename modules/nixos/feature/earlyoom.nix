{ config, lib, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.feature.earlyoom;
in
{
  options.plusultra.feature.earlyoom = with types; {
    enable = mkBoolOpt false "Whether or not to enable earlyoom.";
  };

  config = mkIf cfg.enable {
    services.earlyoom.enable = true;
  };
}
