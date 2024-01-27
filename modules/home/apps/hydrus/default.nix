{ config, lib, pkgs, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.apps.hydrus;
  hydrusDesktopItem = pkgs.makeDesktopItem {
    name = "hydrus-client";
    desktopName = "Hydrus Client";
    exec = "${pkgs.hydrus}/bin/hydrus-client";
  };
in
{
  options.plusultra.apps.hydrus = with types; {
    enable = mkBoolOpt false "Whether or not to enable hydrus.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      hydrus
      hydrusDesktopItem
    ];
  };
}
