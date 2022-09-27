{ config, options, inputs, lib, pkgs, ... }:

with lib;
with lib.my;
let 
  cfg = config.modules.desktop.hyprland;
  inherit (inputs) hyprland;
in {
  options.modules.desktop.hyprland = {
    enable = mkBoolOpt false;
  };

  imports = [
    hyprland.homeManagerModules.default
    # hyprland.nixosModules.default
  ];

  config = mkIf cfg.enable {
    # programs.hyprland.enable = true;
    wayland.windowManager.hyprland = {
      enable = true;
      systemdIntegration = false;
    };
  };
}
