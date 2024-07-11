{ config, lib, pkgs, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.apps.hydrus;
in
{
  options.plusultra.apps.hydrus = with types; {
    enable = mkBoolOpt false "Whether or not to enable hydrus.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      hydrus
    ];
  };
}
