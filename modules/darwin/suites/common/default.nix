{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.suites.common;
in {
  options.plusultra.suites.common = with types; {
    enable = mkBoolOpt false "Whether or not to enable common configuration.";
  };

  config = mkIf cfg.enable {
    programs.fish = enabled;

    plusultra = {
      nix = enabled;

      system = {
        fonts = enabled;
        input = enabled;
        interface = enabled;
      };
    };
  };
}
