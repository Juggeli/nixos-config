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
    environment.systemPackages = with pkgs; [
      rofi
    ];

    plusultra.home.configFile = {
      "rofi/config.rasi".source = ./config.rasi;
      "rofi/catppuccin-mocha.rasi".source = ./catppuccin-mocha.rasi;
    };
  };
}
