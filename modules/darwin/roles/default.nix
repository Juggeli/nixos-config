{ config, lib, ... }:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.roles.darwin-common;
in
{
  options.plusultra.roles.darwin-common = with types; {
    enable = mkBoolOpt false "Whether or not to enable common darwin configuration.";
  };

  config = mkIf cfg.enable {
    programs.fish = enabled;
    plusultra = {
      desktop = {
        yabai = disabled;
        spacebar = disabled;
        skhd = disabled;
        homebrew = enabled;
        aerospace = enabled;
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
