{ config, lib, pkgs, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.apps.kitty;
in
{
  options.plusultra.apps.kitty = with types; {
    enable = mkBoolOpt false "Whether or not to enable kitty.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      kitty
    ];
  };
}
