{ config, lib, pkgs, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.desktop.addons.gtk;
in
{
  options.plusultra.desktop.addons.gtk = with types; {
    enable = mkBoolOpt false "Whether to customize GTK and apply themes.";
  };

  config = mkIf cfg.enable {
    plusultra.home.extraOptions = {
      dconf.settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
        };
      };
      gtk = {
        enable = true;

        theme = {
          name = "Adwaita-dark";
          package = pkgs.gnome.gnome-themes-extra;
        };
      };
    };
  };
}
