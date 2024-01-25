{ config, lib, pkgs, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.desktop.addons.xdg-portal;
in
{
  options.plusultra.desktop.addons.xdg-portal = with types; {
    enable = mkBoolOpt false "Whether or not to add support for xdg portal.";
  };

  config = mkIf cfg.enable {
    xdg.portal = {
      enable = true;
      wlr.enable = true;
    };

    xdg.mime.enable = true;

    environment.systemPackages = with pkgs; [
      xdg-utils
    ];
  };
}
