inputs@{ options, config, lib, pkgs, ... }:

with lib;
with lib.internal;
let
  cfg = config.plusultra.cli-apps.speedtestpp;
in
{
  options.plusultra.cli-apps.speedtestpp = with types; {
    enable = mkBoolOpt false "Whether or not to enable speedtestpp.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      plusultra.speedtestpp
    ];
  };
}

