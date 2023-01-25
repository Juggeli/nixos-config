{ config, options, inputs, lib, pkgs, ... }:

with lib;
with lib.my;
let
  cfg = config.modules.desktop.generic;
  inherit (inputs) webcord-overlay;
in
{
  options.modules.desktop.generic = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      killall
      pcmanfm
      xdg-utils
      hydrus
      webcord-overlay.packages.${pkgs.system}.default
      btop
      powertop
      via
      moreutils
      screen
      memtester
    ];

    services.flatpak.enable = true;
    services.fwupd.enable = true;

    services.udev.extraRules = ''
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0666", TAG+="uaccess", TAG+="udev-acl"
    '';

    fonts = {
      fontDir.enable = true;
      enableGhostscriptFonts = true;
      fonts = with pkgs; [
        ubuntu_font_family
        dejavu_fonts
        symbola
      ];
    };

    user.extraGroups = [ "audio" "video" "docker" ];

    # Resolve .local domains
    services.avahi = {
      enable = true;
      nssmdns = true;
      publish = {
        enable = true;
        addresses = true;
        domain = true;
        hinfo = true;
        userServices = true;
        workstation = true;
      };
    };

    xdg.mime = {
      enable = true;
    };
  };
}
