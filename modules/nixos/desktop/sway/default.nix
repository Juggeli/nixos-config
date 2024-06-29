{ config, lib, pkgs, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.desktop.sway;

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
        gsettings set $gnome_schema gtk-theme 'Catppuccin-Mocha-Compact-Pink-Dark'
      '';
  };
in
{
  options.plusultra.desktop.sway = with types; {
    enable = mkBoolOpt false "Whether or not to enable Sway.";
    extraConfig =
      mkOpt str "" "Additional configuration for the Sway config file.";
  };

  config = mkIf cfg.enable {
    # Desktop additions
    plusultra.desktop.addons = {
      gtk = enabled;
      mako = enabled;
      rofi = enabled;
      xdg-portal = enabled;
      electron-support = enabled;
    };

    programs.sway = {
      enable = true;
      extraPackages = with pkgs; [
        rofi
        swaylock
        swayidle
        xwayland
        sway-contrib.grimshot
        swaylock-fancy
        wl-clipboard
        libinput
        glib # for gsettings
        gtk3.out # for gtk-launch
        gnome.gnome-control-center
        dbus-sway-environment
        configure-gtk
        autotiling-rs
        (catppuccin-gtk.override {
          accents = [ "pink" ];
          size = "compact";
          # tweaks = [ "rimless" "black" ];
          variant = "mocha";
        })
      ];

      extraSessionCommands = ''
        export SDL_VIDEODRIVER=wayland
        export QT_QPA_PLATFORM=wayland
        export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
        export _JAVA_AWT_WM_NONREPARENTING=1
        export MOZ_ENABLE_WAYLAND=1
        export XDG_SESSION_TYPE=wayland
        export XDG_SESSION_DESKTOP=sway
        export XDG_CURRENT_DESKTOP=sway
      '';
    };
    security.pam.services.swaylock = {
      text = ''
        auth include login
      '';
    };

    plusultra.home.extraOptions.wayland.windowManager.sway = {
      enable = true;
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
          "type:keyboard" = {
            xkb_layout = "us,fi";
            xkb_options = "grp:caps_toggle";
          };
        };
        bars = [ ];
        gaps = {
          top = 200;
          left = 300;
          right = 300;
          inner = 6;
        };
        window.commands = [
          {
            command = "floating enable";
            criteria = { app_id = "pavucontrol"; };
          }
          {
            command = "floating enable";
            criteria = { app_id = "mpv"; };
          }
        ];
        keybindings = lib.mkOptionDefault {
          "${modifier}+w" = "kill";
          "${modifier}+space" = "exec ${menu}";
          "${modifier}+Return" = "exec ${terminal}";
          "Print" = ''
            exec ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | wl-copy
          '';
          "F1" = "workspace number 1";
          "F2" = "workspace number 2";
          "F3" = "workspace number 3";
          "F4" = "workspace number 4";
        };
        startup = [
          # { command = "${pkgs.swayidle}/bin/swayidle -w timeout 600 '${pkgs.swaylock}/bin/swaylock -f -i ~/.config/dotfiles/config/bg1.jpg' timeout 150 '${pkgs.sway}/bin/swaymsg \"output * dpms off\"' resume '${pkgs.sway}/bin/swaymsg \"output * dpms on\"' before-sleep '${pkgs.swaylock}/bin/swaylock -f -i ~/.config/dotfiles/config/bg1.jpg'"; }
          { command = "${pkgs.waybar}/bin/waybar"; }
          { command = "${pkgs.autotiling-rs}/bin/autotiling-rs"; }
        ];
        output = {
          DP-1 = {
            mode = "3840x2160@120hz";
            bg = "${./background.png} fill";
          };
        };
      };
      extraConfig = with config.plusultra.colors; ''
        exec dbus-sway-environment
        exec configure-gtk
        output HDMI-A-1 disable
        output HDMI-A-5 disable
        default_border pixel 3
        default_floating_border pixel 3
        client.focused ${base0B} ${base0B} ${base0B} ${base0B}
        client.unfocused ${base03} ${base03} ${base03} ${base03}
        client.focused_inactive ${base03} ${base03} ${base03} ${base03}
      '';
    };

    security.pam.loginLimits = [
      { domain = "@users"; item = "rtprio"; type = "-"; value = 1; }
    ];
  };
}
