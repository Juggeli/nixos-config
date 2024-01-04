{ config, lib, pkgs, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.desktop.addons.gtk;
in
{
  options.plusultra.desktop.addons.gtk = with types; {
    enable = mkBoolOpt false "Whether to customize GTK and apply themes.";
    theme = {
      name =
        mkOpt str "Nordic-darker"
          "The name of the GTK theme to apply.";
      pkg = mkOpt package pkgs.nordic "The package to use for the theme.";
    };
    cursor = {
      name =
        mkOpt str "Nordzy-white-cursors"
          "The name of the cursor theme to apply.";
      pkg = mkOpt package pkgs.nordzy-cursor-theme "The package to use for the cursor theme.";
    };
    icon = {
      name =
        mkOpt str "Papirus"
          "The name of the icon theme to apply.";
      pkg = mkOpt package pkgs.papirus-icon-theme "The package to use for the icon theme.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      cfg.icon.pkg
    ];

    plusultra.home.extraOptions = {
      gtk = {
        enable = true;

        # theme = {
        #   name = cfg.theme.name;
        #   package = cfg.theme.pkg;
        # };
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
