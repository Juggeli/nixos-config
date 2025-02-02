{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.plusultra.cli-apps.nushell;
in
{
  options.plusultra.cli-apps.nushell = {
    enable = mkEnableOption "nushell";
  };

  config = mkIf cfg.enable {
    programs.nushell = {
      enable = true;
    };
  };
}
