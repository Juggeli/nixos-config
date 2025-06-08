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

  windowLayoutSwitcher = pkgs.writeShellApplication {
    name = "window-layout-switcher";

    runtimeInputs = with pkgs; [
      hyprland
      jq
      socat
    ];

    text = builtins.readFile ./window-layout-switcher.sh;
  };

  oledBurnInPrevention = pkgs.writeShellApplication {
    name = "oled-burnin-prevention";

    runtimeInputs = with pkgs; [
      hyprland
      jq
      coreutils
      ddcutil
    ];

    text = ''
      # Prevent OLED burn-in by slightly shifting windows and varying contrast
      window_shift_counter=0
      base_contrast=50
      contrast_high=true  # Start with high contrast
      
      while true; do
        sleep 60  # Check every minute
        
        # Toggle contrast between base and base+2
        if [ "$contrast_high" = true ]; then
          new_contrast=$((base_contrast + 2))
          contrast_high=false
        else
          new_contrast=$base_contrast
          contrast_high=true
        fi
        
        # Set contrast using ddcutil (suppress errors if monitor doesn't support DDC)
        ddcutil setvcp 12 "$new_contrast" 2>/dev/null || true
        
        # Shift windows every 5 minutes (every 5th iteration)
        window_shift_counter=$((window_shift_counter + 1))
        if [ $((window_shift_counter % 5)) -eq 0 ]; then
          # Get all visible windows
          windows=$(hyprctl clients -j | jq -r '.[] | select(.mapped == true and .hidden == false) | .address')
          
          for window in $windows; do
            # Generate small random offset (-2 to +2 pixels)
            x_offset=$((RANDOM % 5 - 2))
            y_offset=$((RANDOM % 5 - 2))
            
            # Move window by small offset
            hyprctl dispatch movewindowpixel "exact $x_offset $y_offset,address:$window" || true
          done
        fi
      done
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

    plusultra.desktop.hyprland = {
      hyprlock.enable = true;
      hypridle.enable = true;
    };

    environment.systemPackages = with pkgs; [
      wl-clipboard
      screenshot
      windowLayoutSwitcher
      oledBurnInPrevention
      wev # Find mouse or keycodes
    ];

    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };

    security = {
      polkit.enable = true;
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
          "vfr" = "true";
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
          "uwsm app -- ${pkgs.hyprpaper}/bin/hyprpaper"
          ''uwsm app -- ${pkgs.hyprland}/bin/hyprctl setcursor "Banana-Catppuccin-Mocha" 64''
          "uwsm app -- window-layout-switcher"
          "uwsm app -- oled-burnin-prevention"
        ];
        debug = {
          "overlay" = "false";
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
    };

    environment.persistence."/persist-home" = {
      users."${config.plusultra.user.name}".files = [
        ".local/share/hyprland/lastVersion"
      ];
    };
  };
}
