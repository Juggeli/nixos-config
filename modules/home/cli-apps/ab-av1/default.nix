{ config, lib, pkgs, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.cli-apps.ab-av1;
in
{
  options.plusultra.cli-apps.ab-av1 = with types; {
    enable = mkBoolOpt false "Whether or not to enable ab-av1.";
  };

  config = mkIf cfg.enable { home.packages = with pkgs; [ ab-av1 ]; };
}
