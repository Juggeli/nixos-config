{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.sway;
    configDir = config.dotfiles.configDir;
in {
  options.modules.desktop.sway = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    programs.sway = {
      enable = true;
      extraPackages = [ 
        pkgs.waybar
        pkgs.rofi-wayland
        pkgs.my.stacki3
        pkgs.pulseaudio
        pkgs.pavucontrol
      ];
      wrapperFeatures = {
        base = true;
        gtk = true;
      };
      extraSessionCommands = ''
        export SDL_VIDEODRIVER=wayland
        export QT_QPA_PLATFORM=wayland
        export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
        export _JAVA_AWT_WM_NONREPARENTING=1
        export XDG_SESSION_TYPE=wayland
        export XDG_CURRENT_DESKTOP=sway
      '';
    };
    environment.variables = {
      XDG_SESSION_TYPE = "wayland";
      XDG_CURRENT_DESKTOP = "sway";
    };

    home.file = let mod = "Mod4"; in {
        ".config/sway/config".text = ''
          set $mod ${mod}
          set $left h
          set $down j
          set $up k
          set $right l
          set $term ${pkgs.alacritty}/bin/alacritty
          set $menu '${pkgs.rofi-wayland}/bin/rofi -modi run, drun, window  -show drun'
          input "*" {
            xkb_layout us,fi
            xkb_options grp:caps_toggle
          }
          gaps {
            top 450
            left 500
            right 500
            inner 6
          }
          for_window [app_id="pavucontrol"] floating enable
          for_window [app_id="mpv"] floating enable

          exec ${pkgs.waybar}/bin/waybar
          exec ${pkgs.my.stacki3}/bin/stacki3

          include sway.theme

          bindsym $mod+Return exec $term
          bindsym $mod+w kill
          bindsym $mod+Space exec $menu
          floating_modifier $mod normal
          bindsym $mod+Shift+r reload
          bindsym $mod+Shift+e exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -B 'Yes, exit sway' 'swaymsg exit'

          bindsym $mod+$left focus left
          bindsym $mod+$down focus down
          bindsym $mod+$up focus up
          bindsym $mod+$right focus right

          bindsym $mod+Shift+$left move left
          bindsym $mod+Shift+$down move down
          bindsym $mod+Shift+$up move up
          bindsym $mod+Shift+$right move right

          bindsym $mod+1 workspace number 1
          bindsym $mod+2 workspace number 2
          bindsym $mod+3 workspace number 3
          bindsym $mod+4 workspace number 4
          bindsym $mod+5 workspace number 5
          bindsym $mod+6 workspace number 6
          bindsym $mod+7 workspace number 7
          bindsym $mod+8 workspace number 8
          bindsym $mod+9 workspace number 9
          bindsym $mod+0 workspace number 10

          bindsym $mod+Shift+1 move container to workspace number 1
          bindsym $mod+Shift+2 move container to workspace number 2
          bindsym $mod+Shift+3 move container to workspace number 3
          bindsym $mod+Shift+4 move container to workspace number 4
          bindsym $mod+Shift+5 move container to workspace number 5
          bindsym $mod+Shift+6 move container to workspace number 6
          bindsym $mod+Shift+7 move container to workspace number 7
          bindsym $mod+Shift+8 move container to workspace number 8
          bindsym $mod+Shift+9 move container to workspace number 9
          bindsym $mod+Shift+0 move container to workspace number 10

          mode "resize" {
              # left will shrink the containers width
              # right will grow the containers width
              # up will shrink the containers height
              # down will grow the containers height
              bindsym $left resize shrink width 20px
              bindsym $down resize grow height 20px
              bindsym $up resize shrink height 20px
              bindsym $right resize grow width 20px

              # Return to default mode
              bindsym Return mode "default"
              bindsym Escape mode "default"
          }
          bindsym $mod+r mode "resize"
        '';
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