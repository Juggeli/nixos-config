{
  config,
  lib,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.services.kdeconnect;
in
{
  options.plusultra.services.kdeconnect = {
    enable = mkBoolOpt false "Whether or not to enable kdeconnect.";
  };

  config = mkIf cfg.enable {
    programs.kdeconnect.enable = true;
  };
}
