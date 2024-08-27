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
      xdg-portal = enabled;
      electron-support = enabled;
    };

    environment.systemPackages = with pkgs; [
      wl-clipboard
      screenshot
      wev # Find mouse or keycodes
    ];

    programs.hyprland.enable = true;

    plusultra.home.extraOptions.wayland.windowManager.hyprland = {
      enable = true;
      settings = {
        "$mod" = "SUPER";
        bind = [
          "$mod, Space, exec, rofi -show combi"
          "$mod, B, exec, firefox"
          ", Print, exec, screenshot"
          "$mod, Return, exec, kitty"
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
          "float,^(mpv)$"
          "suppressevent maximize,^(mpv)$"
        ];
        exec-once = [
          "${pkgs.waybar}/bin/waybar"
          "${pkgs.hyprpaper}/bin/hyprpaper"
          "${pkgs.hyprland-per-window-layout}/bin/hyprland-per-window-layout"
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
