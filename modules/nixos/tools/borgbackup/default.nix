{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.tools.borgbackup;
in
{
  options.plusultra.tools.borgbackup = with types; {
    enable = mkBoolOpt false "Whether or not to install borgbackup globally.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      borgbackup
    ];
  };
}