{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.sway;
    configDir = config.dotfiles.configDir;

    # bash script to let dbus know about important env variables and
    # propogate them to relevent services run at the end of sway config
    # see
    # https://github.com/emersion/xdg-desktop-portal-wlr/wiki/"It-doesn't-work"-Troubleshooting-Checklist
    dbus-sway-environment = pkgs.writeTextFile {
      name = "dbus-sway-environment";
      destination = "/bin/dbus-sway-environment";
      executable = true;

      text = ''
    dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
    systemctl --user stop pipewire wireplumber xdg-desktop-portal xdg-desktop-portal-wlr
    systemctl --user start pipewire wireplumber xdg-desktop-portal xdg-desktop-portal-wlr
        '';
    };

    # currently, there is some friction between sway and gtk:
    # https://github.com/swaywm/sway/wiki/GTK-3-settings-on-Wayland
    # the suggested way to set gtk settings is with gsettings
    # for gsettings to work, we need to tell it where the schemas are
    # using the XDG_DATA_DIR environment variable
    # run at the end of sway config
    configure-gtk = pkgs.writeTextFile {
        name = "configure-gtk";
        destination = "/bin/configure-gtk";
        executable = true;
        text = let
          schema = pkgs.gsettings-desktop-schemas;
          datadir = "${schema}/share/gsettings-schemas/${schema.name}";
        in ''
          export XDG_DATA_DIRS=${datadir}:$XDG_DATA_DIRS
          gnome_schema=org.gnome.desktop.interface
          gsettings set $gnome_schema gtk-theme 'Dracula'
          '';
    };

in {
  options.modules.desktop.sway = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    programs.sway = {
      enable = true;
      extraPackages = with pkgs; [ 
        swayidle
        swaylock
        waybar
        rofi-wayland
        my.stacki3
        glib
        gnome3.adwaita-icon-theme # Default gnome cursors
        dbus-sway-environment
        configure-gtk
        grim
        slurp
        wl-clipboard
        mako
        vulkan-tools
        vulkan-validation-layers
        xorg.xeyes
      ];
      wrapperFeatures.gtk = true;
    };
    environment.variables = {
      XDG_SESSION_TYPE = "wayland";
      XDG_CURRENT_DESKTOP = "sway";
      GTK_THEME = "Dracula";
      WLR_NO_HARDWARE_CURSORS = "1";
      SDL_VIDEODRIVER = "wayland";
      QT_QPA_PLATFORM = "wayland";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      _JAVA_AWT_WM_NONREPARENTING = "1";
#      WLR_RENDERER = "vulkan";
    };

    # xdg-desktop-portal works by exposing a series of D-Bus interfaces
    # known as portals under a well-known name
    # (org.freedesktop.portal.Desktop) and object path
    # (/org/freedesktop/portal/desktop).
    # The portal interfaces include APIs for file access, opening URIs,
    # printing and others.
    services.dbus.enable = true;
    xdg.portal = {
      enable = true;
      wlr.enable = true;
      # gtk portal needed to make gtk apps happy
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      gtkUsePortal = true;
    };

    home.programs.mako = {
      enable = true;
      anchor = "bottom-center";
      backgroundColor = "#282a36";
      textColor = "#888faf";
      borderColor = "#282a36";
      extraConfig = ''
        [urgency=low]
        border-color=#282a36

        [urgency=normal]
        border-color=#f1fa8c

        [urgency=high]
        border-color=#ff5555
      '';
    };

    home.sway = {
      enable = true;
      config = rec {
        modifier = "Mod4";
        left = "h";
        down = "j";
        up = "k";
        right = "l";
        terminal = "${pkgs.alacritty}/bin/alacritty";
        menu = "'${pkgs.rofi-wayland}/bin/rofi -modi run, drun, window  -show drun'";
        input = {
          "type:keyboard" = { xkb_layout = "us,fi"; xkb_options = "grp:caps_toggle"; };
        };
        bars = [];
        gaps = { top = 450; left = 500; right = 500; inner = 6; };
        window.commands = [
          { command = "floating enable"; criteria = { app_id = "pavucontrol"; }; }
          { command = "floating enable"; criteria = { app_id = "mpv"; }; }
        ];
        keybindings = lib.mkOptionDefault {
          "${modifier}+w" = "kill";
          "${modifier}+space" = "exec ${menu}";
          "${modifier}+Return" = "exec ${terminal}";
          "Print" = ''
            exec ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | wl-copy
          '';
        };
        startup = [
          { command = "${pkgs.swayidle}/bin/swayidle -w timeout 300 '${pkgs.swaylock}/bin/swaylock -f -c 000000' timeout 150 '${pkgs.sway}/bin/swaymsg \"output * dpms off\"' resume '${pkgs.sway}/bin/swaymsg \"output * dpms on\"' before-sleep '${pkgs.swaylock}/bin/swaylock -f -c 000000'";}
          { command = "${pkgs.waybar}/bin/waybar"; }
          { command = "${pkgs.my.stacki3}/bin/stacki3"; }
        ];
      };
      extraConfig = ''
          include sway.theme
          exec dbus-sway-environment
          exec configure-gtk
        '';
    };

    home.file = let mod = "Mod4"; in {
        ".config/waybar/config".text = ''
          {
            "layer": "top",
            "position": "bottom",
            "margin-top": 6,
            "margin-left": 1200,
            "margin-right": 1200,
            "margin-bottom": 50,
            "modules-left": ["sway/workspaces"],
            "modules-center": ["sway/window"],
            "modules-right": ["pulseaudio", "tray", "clock"],
          }
        '';
    };
  };
}
