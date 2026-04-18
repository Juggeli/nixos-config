{ config, lib, ... }:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.suites.development;
in
{
  options.plusultra.suites.development = with types; {
    enable = mkBoolOpt false "Whether or not to enable common development configuration.";
  };

  config = mkIf cfg.enable {
    plusultra = {
      tools = {
        rust = enabled;
      };
    };
  };
}
