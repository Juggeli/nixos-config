{ config, lib, pkgs, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.feature.graphical;
in
{
  options.plusultra.feature.graphical = with types; {
    enable = mkOption {
      default = false;
      type = with types; bool;
      description = "Enables graphical boot screen";
    };
  };

  config = mkIf cfg.enable {
    boot = {
      plymouth = {
        enable = true;
        theme = "lone";
        themePackages = [ (pkgs.adi1090x-plymouth-themes.override { selected_themes = [ "lone" ]; }) ];
      };
    };
  };
}
