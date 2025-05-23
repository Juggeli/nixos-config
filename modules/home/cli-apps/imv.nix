{
  config,
  lib,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.cli-apps.imv;
in
{
  options.plusultra.cli-apps.imv = with types; {
    enable = mkBoolOpt false "Whether or not to enable imv.";
  };

  config = mkIf cfg.enable {
    programs.imv = {
      enable = true;
    };
    catppuccin.imv.enable = true;
  };
}
