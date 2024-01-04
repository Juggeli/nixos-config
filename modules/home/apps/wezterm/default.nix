{ config, lib, pkgs, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.apps.wezterm;
in
{
  options.plusultra.apps.wezterm = with types; {
    enable = mkEnableOption "Whether or not to enable wezterm.";
    fontSize = mkOpt types.str "13" "Font size to use with wezterm.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      wezterm
    ];
    xdg.configFile = {
      "wezterm/wezterm.lua".text = import ./wezterm.lua cfg;
    };
  };
}
