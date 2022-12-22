{ options, config, pkgs, lib, ... }:
with lib;
with lib.my;
let cfg = config.modules.desktop.kde;
in
{
  options.modules.desktop.kde = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.xserver = {
      enable = true;
      displayManager.sddm.enable = true;
      displayManager.sessionPackages = [ pkgs.sway ];
      desktopManager.plasma5.enable = true;
    };

    environment.systemPackages = with pkgs; [
      libsForQt5.bismuth
    ];

    services.xserver.desktopManager.plasma5.excludePackages = with pkgs.libsForQt5; [
      elisa
      khelpcenter
      konsole
    ];

    environment.variables = {
      NIXOS_OZONE_WL = "1";
    };
  };
}


