{ options, config, pkgs, lib, ... }:
with lib;
with lib.my;
let cfg = config.modules.desktop.gnome;
in
{
  options.modules.desktop.gnome = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      displayManager.gdm.wayland = true;
      displayManager.sessionPackages = [ pkgs.sway ];
      desktopManager.gnome.enable = true;
    };

    environment.systemPackages = with pkgs; [
      gnomeExtensions.pop-shell
      gnome.adwaita-icon-theme
      gnome.gnome-tweaks
      pop-gtk-theme
      pop-icon-theme
    ];

    environment.variables = {
      NIXOS_OZONE_WL = "1";
    };
  };
}


