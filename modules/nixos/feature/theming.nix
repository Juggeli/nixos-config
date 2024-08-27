{ config, lib, ... }:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.feature.theming;
in
{
  options.plusultra.feature.theming = with types; {
    enable = mkOption {
      default = false;
      type = with types; bool;
      description = "Enables Catppuccin theming";
    };
  };

  config = mkIf cfg.enable {
    catppuccin = {
      enable = true;
      flavor = "mocha";
      accent = "pink";
    };
  };
}
