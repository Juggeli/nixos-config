{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.desktop.hyprland;

  # Catppuccin-Mocha
  surface0 = "0xff313244";
  red = "0xffa6e3a1";

  workspaces = builtins.concatLists (
    builtins.genList (
      x:
      let
        ws =
          let
            c = (x + 1) / 10;
          in
          builtins.toString (x + 1 - (c * 10));
      in
      [
        "$mod, ${ws}, workspace, ${toString (x + 1)}"
        ", F${ws}, workspace, ${toString (x + 1)}"
        "$mod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
      ]
    ) 10
  );

  screenshot = pkgs.writeShellApplication {
    name = "screenshot";

    runtimeInputs = with pkgs; [
      grim
      slurp
      wl-clipboard
    ];

    text = ''
      grim -g "$(slurp)" - | wl-copy
    '';
  };
in
{
  options.plusultra.desktop.hyprland = with types; {
    enable = mkBoolOpt false "Whether or not to enable Hyprland.";
  };

  config = mkIf cfg.enable {
    plusultra.desktop.addons = {
      gtk = enabled;
      qt = enabled;
      mako = enabled;
      rofi = enabled;
      electron-support = enabled;
    };

    environment.systemPackages = with pkgs; [
      wl-clipboard
      screenshot
      wev # Find mouse or keycodes
      hyprlock
      playerctl
    ];

    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };

    plusultra.home.extraOptions.services = {
      hypridle = {
        enable = true;
        settings = {
          general = {
            before_sleep_cmd = "loginctl lock-session & playerctl pause";
            after_sleep_cmd = "hyprctl dispatch dpms on";
            ignore_dbus_inhibit = false;
            lock_cmd = "pidof hyprlock || hyprlock -q";
          };
          listener = [
            {
              timeout = 300;
              on-timeout = "hyprlock";
            }
            {
              timeout = 360;
              on-timeout = "hyprctl dispatch dpms off";
              on-resume = "hyprctl dispatch dpms on";
            }
            {
              timeout = 1800;
              on-timeout = "systemctl suspend";
            }
          ];
        };
      };
    };

    security = {
      polkit.enable = true;
      pam.services.hyprlock = { };
    };

    plusultra.home.extraOptions.programs.hyprlock = {
      enable = true;
      settings = {
        general = {
          disable_loading_bar = true;
          grace = 10;
          hide_cursor = true;
          no_fade_in = false;
        };
        background = [
          {
            path = "~/.config/hypr/background.png";
            blur_passes = 3;
            blur_size = 8;
          }
        ];
        # image = [
        #   {
        #     path = "/home/${username}/.config/face.jpg";
        #     size = 150;
        #     border_size = 4;
        #     border_color = "rgb(0C96F9)";
        #     rounding = -1; # Negative means circle
        #     position = "0, 200";
        #     halign = "center";
        #     valign = "center";
        #   }
        # ];
        input-field = [
          {
            size = "200, 50";
            position = "0, -80";
            monitor = "";
            dots_center = true;
            fade_on_empty = false;
            font_color = "rgb(CFE6F4)";
            inner_color = "rgb(657DC2)";
            outer_color = "rgb(0D0E15)";
            outline_thickness = 5;
            placeholder_text = "Password...";
            shadow_passes = 2;
          }
        ];
      };
    };

    plusultra.home.extraOptions.wayland.windowManager.hyprland = {
      enable = true;
      settings = {
        "$mod" = "SUPER";
        bind = [
          "$mod, Space, exec, uwsm app -- rofi -show combi"
          "$mod, B, exec, uwsm app -- firefox"
          ", Print, exec, uwsm app -- screenshot"
          "$mod, Return, exec, uwsm app -- kitty"
          "$mod, W, killactive"
          "$mod Shift, E, exit"
          "$mod, T, togglefloating"
          "$mod, F, fullscreen"

          # Groups
          "$mod, G, togglegroup"
          "Control Shift, bracketleft, changegroupactive, b"
          "Control Shift, bracketright, changegroupactive, f"

          # Move focus
          "$mod, H, movefocus, l"
          "$mod, L, movefocus, r"
          "$mod, K, movefocus, u"
          "$mod, J, movefocus, d"

          # Move window
          "$mod Shift, H, movewindow, l"
          "$mod Shift, L, movewindow, r"
          "$mod Shift, K, movewindow, u"
          "$mod Shift, J, movewindow, d"
        ] ++ workspaces;
        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
        ];
        input = {
          "kb_layout" = "us,fi";
          "kb_options" = "grp:caps_toggle";
          "follow_mouse" = 1;
          "sensitivity" = 0;
        };
        general = {
          "gaps_in" = 5;
          "gaps_out" = 0;
          "border_size" = 3;
          "col.active_border" = red;
          "col.inactive_border" = surface0;
          "layout" = "dwindle";
        };
        misc = {
          "disable_hyprland_logo" = "yes";
          "disable_splash_rendering" = "yes";
        };
        decoration = {
          "rounding" = 0;
          blur = {
            "enabled" = "false";
          };
        };
        dwindle = {
          "pseudotile" = "true";
          "preserve_split" = "true";
          "force_split" = 2;
        };
        monitor = [
          "DP-3,3840x2160@120,0x0,1"
          "DP-3,addreserved,200,0,300,300"
          "HDMI-A-1,disable"
          "HDMI-A-5,disable"
          "Unknown-1,disable"
        ];
        windowrule = [
          "float,class:mpv"
          "suppressevent maximize,class:mpv"
        ];
        exec-once = [
          "uwsm app -- ${pkgs.waybar}/bin/waybar"
          "uwsm app -- ${pkgs.hyprpaper}/bin/hyprpaper"
          "uwsm app -- ${pkgs.hyprland-per-window-layout}/bin/hyprland-per-window-layout"
          ''uwsm app -- ${pkgs.hyprland}/bin/hyprctl setcursor "Banana-Catppuccin-Mocha" 64''
        ];
        debug = {
          "overlay" = "false";
        };
        misc = {
          "vfr" = "true";
        };
        env = [
          "LIBVA_DRIVER_NAME,nvidia"
          "XDG_SESSION_TYPE,wayland"
          "GBM_BACKEND,nvidia-drm"
          "__GLX_VENDOR_LIBRARY_NAME,nvidia"
          "WLR_NO_HARDWARE_CURSORS,1"
        ];
        animations = {
          "enabled" = "true";
          "bezier" = [
            "overshot, 0.05, 0.9, 0.1, 1.05"
            "smoothOut, 0.36, 0, 0.66, -0.56"
            "smoothIn, 0.25, 1, 0.5, 1"
          ];
          "animation" = [
            "windows, 1, 3, overshot, slide"
            "windowsOut, 1, 3, smoothOut, slide"
            "windowsMove, 1, 3, default"
            "border, 1, 3, default"
            "fade, 1, 3, smoothIn"
            "fadeDim, 1, 3, smoothIn"
            "workspaces, 1, 3, default"
          ];
        };
      };
    };

    plusultra.home.configFile = {
      "hypr/hyprpaper.conf".source = ./hyprpaper.conf;
      "hypr/background.png".source = ./background.png;
      "hyprland-per-window-layout/options.toml".source = ./hyprland-per-window-layout.toml;
    };
  };
}
