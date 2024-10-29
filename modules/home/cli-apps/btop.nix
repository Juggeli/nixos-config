{
  config,
  lib,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.cli-apps.btop;
in
{
  options.plusultra.cli-apps.btop = with types; {
    enable = mkBoolOpt false "Whether or not to enable btop.";
  };

  config = mkIf cfg.enable {
    programs.btop = {
      enable = true;
      catppuccin.enable = true;
    };
  };
}
