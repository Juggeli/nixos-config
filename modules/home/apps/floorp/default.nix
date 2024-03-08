{ config, lib, pkgs, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.apps.floorp;
in
{
  options.plusultra.apps.floorp = with types; {
    enable = mkBoolOpt false "Whether or not to enable floorp.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      floorp
    ];
    plusultra.user.impermanence.directories = [
      ".cache/floorp"
      ".floorp"
    ];
  };
}
