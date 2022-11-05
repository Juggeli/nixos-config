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
        gsettings set $gnome_schema gtk-theme 'Adwaita-dark'
      '';
  };
in
{
  options.modules.desktop.sway = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hm.home.packages = with pkgs; [
      swayidle
      swaylock
      waybar
      rofi-wayland
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
      autotiling-rs
    ];

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

    hm.programs.mako = {
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

    hm.wayland.windowManager.sway = {
      enable = true;
      extraOptions = [
        "--unsupported-gpu"
      ];
      extraSessionCommands = ''
        export XDG_SESSION_TYPE=wayland
        export XDG_CURRENT_DESKTOP=sway
        export GDK_BACKEND=wayland
        export SDL_VIDEODRIVER=wayland
        export QT_QPA_PLATFORM=wayland
        export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
        export _JAVA_AWT_WM_NONREPARENTING=1
        export NIXOS_OZONE_WL=1
        export EGL_PLATFORM=wayland
      '';
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
        terminal = "${pkgs.kitty}/bin/kitty";
        menu = "'${pkgs.rofi-wayland}/bin/rofi -modi run, drun, window  -show drun'";
        input = {
          "type:keyboard" = { xkb_layout = "us,fi"; xkb_options = "grp:caps_toggle"; };
        };
        bars = [ ];
        gaps = { top = 250; left = 450; right = 450; inner = 6; };
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
          # { command = "${pkgs.swayidle}/bin/swayidle -w timeout 600 '${pkgs.swaylock}/bin/swaylock -f -i ~/.config/dotfiles/config/bg1.jpg' timeout 150 '${pkgs.sway}/bin/swaymsg \"output * dpms off\"' resume '${pkgs.sway}/bin/swaymsg \"output * dpms on\"' before-sleep '${pkgs.swaylock}/bin/swaylock -f -i ~/.config/dotfiles/config/bg1.jpg'"; }
          { command = "${pkgs.waybar}/bin/waybar"; }
          { command = "${pkgs.autotiling-rs}/bin/autotiling-rs"; }
        ];
        output = {
          DP-1 = {
            mode = "3840x2160@120hz";
          };
        };
      };
      extraConfig = ''
        exec dbus-sway-environment
        exec configure-gtk
        include sway.theme
        output HDMI-A-1 disable
        output DP-1 bg ~/.config/dotfiles/config/bg1.jpg fill
        default_border pixel 3
        default_floating_border pixel 3
        client.focused #98be65 #98be65 #98be65 #98be65 
        client.unfocused #3f444a #3f444a #3f444a #3f444a 
        client.focused_inactive #3f444a #3f444a #3f444a #3f444a 
      '';
    };

    hm.xdg.configFile."waybar/config".text = ''
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
    hm.xdg.configFile."waybar/style.css".text = ''
      * {
        transition: none;
        box-shadow: none;
      }

      #waybar {
        color: #bbc2cf;
        background: #282c34;
      }

      #workspaces {
        margin: 0 4px;
      }

      #workspaces button {
        margin: 4px 0;
        padding: 0 6px;
        color: #bbc2cf;
        border: none;
        border-radius: 0;
      }

      #workspaces button:hover {
        background: #5B6268;
      }

      #workspaces button.visible {
      }

      #workspaces button.focused {
        border-radius: 4px;
        background-color: #3f444a;
      }

      #tray {
        margin: 4px 16px 4px 4px;
        border-radius: 4px;
        background-color: #3f444a;
      }

      #tray *:first-child {
        border-left: none;
      }

      #mode, #battery, #cpu, #memory, #network, #pulseaudio, #idle_inhibitor, #backlight, #custom-storage, #custom-spotify, #custom-weather, #custom-mail, #clock, #temperature {
        margin: 4px 2px;
        padding: 0 6px;
        background-color: #3f444a;
        border-radius: 4px;
        min-width: 20px;
      }

      #clock {
        margin-left: 12px;
        margin-right: 4px;
        background-color: transparent;
      }
    '';
  };
}
