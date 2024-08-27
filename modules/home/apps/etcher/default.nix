{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.apps.etcher;
in
{
  options.plusultra.apps.etcher = with types; {
    enable = mkBoolOpt false "Whether or not to enable etcher.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Etcher is currently broken in nixpkgs, temporarily replaced with
      # gnome disk utility.
      # etcher
      gnome.gnome-disk-utility
    ];
  };
}
