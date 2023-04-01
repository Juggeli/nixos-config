{ options, config, lib, pkgs, ... }:

with lib;
with lib.internal;
let
  cfg = config.plusultra.suites.development;
in
{
  options.plusultra.suites.development = with types; {
    enable = mkBoolOpt false
      "Whether or not to enable common development configuration.";
  };

  config = mkIf cfg.enable {
    plusultra = {
      tools = {
        rust = enabled;
      };
    };
  };
}
