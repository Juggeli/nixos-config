{ config, lib, ... }:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.suites.social;
in
{
  options.plusultra.suites.social = with types; {
    enable = mkBoolOpt false "Whether or not to enable social configuration.";
  };

  config = mkIf cfg.enable {
    plusultra = { };
  };
}
