{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.cli-apps.speedtestpp;
in
{
  options.plusultra.cli-apps.speedtestpp = with types; {
    enable = mkBoolOpt false "Whether or not to enable speedtestpp.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      plusultra.speedtestpp
    ];
  };
}
