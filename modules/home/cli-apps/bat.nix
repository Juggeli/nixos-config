{
  config,
  lib,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.cli-apps.bat;
in
{
  options.plusultra.cli-apps.bat = with types; {
    enable = mkBoolOpt false "Whether or not to enable bat.";
  };

  config = mkIf cfg.enable {
    programs.bat = {
      enable = true;
      catppuccin.enable = true;
    };
  };
}
