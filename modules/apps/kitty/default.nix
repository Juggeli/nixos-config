inputs@{ options, config, lib, pkgs, ... }:

with lib;
with lib.internal;
let
  cfg = config.plusultra.apps.kitty;
in
{
  options.plusultra.apps.kitty = with types; {
    enable = mkBoolOpt false "Whether or not to enable kitty.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      kitty
    ];
  };
}
