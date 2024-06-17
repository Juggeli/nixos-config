{ config, lib, pkgs, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.cli-apps.jq;
in
{
  options.plusultra.cli-apps.jq = with types; {
    enable = mkBoolOpt false "Whether or not to enable jq.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      jq
    ];
  };
}
