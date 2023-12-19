inputs @ {
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.cli-apps.imv;
in {
  options.plusultra.cli-apps.imv = with types; {
    enable = mkBoolOpt false "Whether or not to enable imv.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      imv
    ];
  };
}
