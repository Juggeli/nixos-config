inputs@{ options, config, lib, pkgs, ... }:

with lib;
with lib.internal;
let
  cfg = config.plusultra.apps.wezterm;
in
{
  options.plusultra.apps.wezterm = with types; {
    enable = mkBoolOpt false "Whether or not to enable wezterm.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      wezterm
    ];

    plusultra.home = {
      configFile = {
        "wezterm/wezterm.lua".source = ./wezterm.lua;
      };
    };
  };
}

