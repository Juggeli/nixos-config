{ config, lib, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.desktop.addons.qt;
in
{
  options.plusultra.desktop.addons.qt = with types; {
    enable = mkBoolOpt false "Whether to customize QT and apply themes.";
  };

  config = mkIf cfg.enable {
    plusultra.home.extraOptions = {
      qt = {
        enable = true;
        platformTheme.name = "adwaita";
        style.name = "adwaita-dark";
      };
    };
  };
}
