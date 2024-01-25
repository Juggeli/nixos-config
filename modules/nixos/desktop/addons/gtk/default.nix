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
      gtk = {
        enable = true;

        theme = {
          name = "Catppuccin-Mocha-Compact-Pink-Dark";
          package = pkgs.catppuccin-gtk.override {
            accents = [ "pink" ];
            size = "compact";
            tweaks = [ "rimless" "black" ];
            variant = "mocha";
          };
        };

        cursorTheme = {
          name = "Catppuccin-Mocha-Pink-Cursors";
          package = pkgs.catppuccin-cursors.mochaPink;
        };

        iconTheme = {
          name = "Papirus";
          package = pkgs.papirus-icon-theme;
        };
      };
    };
  };
}
