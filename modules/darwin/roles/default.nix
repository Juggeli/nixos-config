{ config, lib, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.roles.darwin-common;
in
{
  options.plusultra.roles.darwin-common = with types; {
    enable = mkBoolOpt false "Whether or not to enable common darwin configuration.";
  };

  config = mkIf cfg.enable {
    plusultra = {
      desktop = {
        yabai = enabled;
        spacebar = enabled;
        skhd = enabled;
      };
      system = {
        nix = enabled;
        fonts = enabled;
        input = enabled;
        interface = enabled;
      };
    };
  };
}
