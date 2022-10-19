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
      vifm
      webcord-overlay.packages.${pkgs.system}.default
      btop
    ];

    fonts = {
      fontDir.enable = true;
      enableGhostscriptFonts = true;
      fonts = with pkgs; [
        ubuntu_font_family
        dejavu_fonts
        symbola
      ];
    };

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = ''
            	     ${pkgs.greetd.tuigreet}/bin/tuigreet -r -t --cmd "${pkgs.sway}/bin/.sway-wrapped --unsupported-gpu"
          '';
          user = "greeter";
        };
      };
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

    # Try really hard to get QT to respect my GTK theme.
    env.GTK_DATA_PREFIX = [ "${config.system.path}" ];
    env.QT_QPA_PLATFORMTHEME = "gnome";
    env.QT_STYLE_OVERRIDE = "kvantum";

    xdg.mime = {
      enable = true;
    };

    # For rust packages 
    env.PATH = [ "$HOME/.cargo/bin" ];

    # Clean up leftovers, as much as we can
    system.userActivationScripts.cleanupHome = ''
      pushd "${config.user.home}"
      rm -rf .compose-cache .nv .pki .dbus .fehbg
      [ -s .xsession-errors ] || rm -f .xsession-errors*
      popd
    '';
  };
}
