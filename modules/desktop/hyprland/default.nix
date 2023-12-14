{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.plusultra.desktop.hyprland;
  term = config.plusultra.desktop.addons.term;
  substitutedConfig = pkgs.substituteAll {
    src = ./config;
    term = term.pkg.pname or term.pkg.name;
  };
in {
  options.plusultra.desktop.hyprland = with types; {
    enable = mkBoolOpt false "Whether or not to enable Hyprland.";
    wallpaper = mkOpt (nullOr package) null "The wallpaper to display.";
    extraConfig =
      mkOpt str "" "Additional configuration for the Hyprland config file.";
  };

  # config = mkIf cfg.enable {
  #   # Desktop additions
  #   plusultra.desktop.addons = {
  #     gtk = enabled;
  #     mako = enabled;
  #     rofi = enabled;
  #     waybar = enabled;
  #     xdg-portal = enabled;
  #     electron-support = enabled;
  #   };
  #
  #   environment.systemPackages = with pkgs; [
  #     hyprpaper
  #   ];
  #
  #   programs.hyprland = {
  #     enable = true;
  #   };
  #
  #   plusultra.home.configFile = {
  #     "hypr/hyprland.conf".source = ./hyprland.conf;
  #     "hypr/catppuccin-mocha.conf".source = ./catppuccin-mocha.conf;
  #     "hypr/hyprpaper.conf".source = ./hyprpaper.conf;
  #     "hypr/background.png".source = ./background.png;
  #   };
  # };
}
