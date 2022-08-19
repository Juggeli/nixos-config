{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let
  cfg = config.modules.desktop;

  my-python-packages = python-packages: with python-packages; [
    pyserial
    intelhex
  ];
  python-with-my-packages = pkgs.python3.withPackages my-python-packages;
in {
  config = {
    user.packages = with pkgs; [
      qgnomeplatform        # QPlatformTheme for a better Qt application inclusion in GNOME
      libsForQt5.qtstyleplugin-kvantum # SVG-based Qt5 theme engine plus a config tool and extra theme
      vscode
      killall
      discord
      pcmanfm
      nnn
      xdg-utils
      hydrus
      vifm
      neovim
      trash-cli
      python-with-my-packages
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

    # Clean up leftovers, as much as we can
    system.userActivationScripts.cleanupHome = ''
      pushd "${config.user.home}"
      rm -rf .compose-cache .nv .pki .dbus .fehbg
      [ -s .xsession-errors ] || rm -f .xsession-errors*
      popd
    '';
  };
}
