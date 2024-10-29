{
  config,
  lib,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.cli-apps.yazi;
in
{
  options.plusultra.cli-apps.yazi = with types; {
    enable = mkBoolOpt false "Whether or not to enable yazi.";
  };

  config = mkIf cfg.enable {
    programs.yazi = {
      enable = true;
      enableFishIntegration = true;
      catppuccin.enable = true;
      settings = {
        preview = {
          image_delay = 0;
        };
      };
    };
  };
}
