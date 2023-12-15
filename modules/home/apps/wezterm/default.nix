inputs @ {
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.apps.wezterm;
in {
  options.plusultra.apps.wezterm = with types; {
    enable = mkBoolOpt false "Whether or not to enable wezterm.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      wezterm
    ];
    xdg.configFile = {
      "wezterm/wezterm.lua".source = ./wezterm.lua;
    };
  };
}
