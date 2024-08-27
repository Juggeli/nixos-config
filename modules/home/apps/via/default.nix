{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.apps.via;
in
{
  options.plusultra.apps.via = with types; {
    enable = mkBoolOpt false "Whether or not to enable via.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      via
    ];
  };
}
