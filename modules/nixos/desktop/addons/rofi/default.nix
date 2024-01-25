{ config, lib, pkgs, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.desktop.addons.rofi;
in
{
  options.plusultra.desktop.addons.rofi = with types; {
    enable =
      mkBoolOpt false "Whether to enable Rofi in the desktop environment.";
  };

  config = mkIf cfg.enable {
    plusultra.home.extraOptions.programs.rofi = {
      enable = true;
      package = pkgs.rofi-wayland;
      theme = ./catppuccin-mocha.rasi;
      terminal = "kitty";
      plugins = with pkgs; [
        rofi-power-menu
        rofi-calc
      ];
      extraConfig = {
        modi = "drun,run,combi,calc,power-menu:${pkgs.rofi-power-menu}/bin/rofi-power-menu";
        combi-modi = "drun,calc,power-menu:${pkgs.rofi-power-menu}/bin/rofi-power-menu";
        combi-hide-mode-prefix = true;
        show-icons = true;
      };
    };
  };
}
