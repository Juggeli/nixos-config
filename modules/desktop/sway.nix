{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let
  cfg = config.modules.desktop.sway;
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
    text =
      let
        schema = pkgs.gsettings-desktop-schemas;
        datadir = "${schema}/share/gsettings-schemas/${schema.name}";
      in
      ''
        export XDG_DATA_DIRS=${datadir}:$XDG_DATA_DIRS
        gnome_schema=org.gnome.desktop.interface
        gsettings set $gnome_schema gtk-theme 'Dracula'
      '';
  };

  my-python-packages = python-packages: with python-packages; [
    i3ipc
  ];
  python-with-packages = pkgs.python3.withPackages my-python-packages;
in
{
  options.modules.desktop.sway = {
    enable = mkBoolOpt false;
    # wallpaper = mkOpt' (types.either types.str types.path) "";
    # wallpaper = mkOpt types.path ./config/bg1.jpg;
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      swayidle
      swaylock
      waybar
      rofi-wayland
      my.stacki3
      glib
      gnome.adwaita-icon-theme # Default gnome cursors
      dbus-sway-environment
      configure-gtk
      grim
      slurp
      wl-clipboard
      mako
      vulkan-tools
      vulkan-validation-layers
      swaybg
      wl-gammactl
      python-with-packages
    ];
    environment.variables = {
      XDG_SESSION_TYPE = "wayland";
      XDG_CURRENT_DESKTOP = "sway";
      GDK_BACKEND = "wayland";
      GTK_THEME = "Dracula";
      SDL_VIDEODRIVER = "wayland";
      QT_QPA_PLATFORM = "wayland";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      _JAVA_AWT_WM_NONREPARENTING = "1";
      NIXOS_OZONE_WL = "1";
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

    security.pam.services.swaylock = {
      text = ''
        auth include login
      '';
    };

    home.sway = {
      enable = true;
      extraOptions = [
        "--unsupported-gpu"
      ];
      wrapperFeatures = {
        base = true;
        gtk = true;
      };
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
        bars = [ ];
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
          { command = "${pkgs.swayidle}/bin/swayidle -w timeout 300 '${pkgs.swaylock}/bin/swaylock -f -i ~/.config/dotfiles/config/bg1.jpg' timeout 150 '${pkgs.sway}/bin/swaymsg \"output * dpms off\"' resume '${pkgs.sway}/bin/swaymsg \"output * dpms on\"' before-sleep '${pkgs.swaylock}/bin/swaylock -f -i ~/.config/dotfiles/config/bg1.jpg'"; }
          { command = "${pkgs.waybar}/bin/waybar"; }
          { command = "${pkgs.my.stacki3}/bin/stacki3"; }
          { command = "${python-with-packages}/bin/python ~/.config/dotfiles/config/autodim.py"; }
          { command = "~/koodi/slurp/asbl.sh"; }
        ];
        output = {
          DP-1 = {
            mode = "3840x2160@120hz";
            # bg = "#000000 solid_color";
          };
        };
      };
      extraConfig = ''
        exec dbus-sway-environment
        exec configure-gtk
        include sway.theme
        output HDMI-A-1 disable
        output DP-1 bg ~/.config/dotfiles/config/bg1.jpg fill
      '';
    };

    home.file = let mod = "Mod4"; in
      {
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
