{ config, lib, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.desktop.waybar;
in
{
  options.plusultra.desktop.waybar = with types; {
    enable =
      mkBoolOpt false "Whether to enable Waybar in the desktop environment.";
  };

  config = mkIf cfg.enable {
    programs.waybar = {
      enable = true;
      settings = {
        mainBar = {
          layer = "top";
          position = "bottom";
          margin-top = 6;
          margin-left = 1200;
          margin-right = 1200;
          margin-bottom = 6;
          height = 40;
          modules-left = [ "custom/logo" "hyprland/workspaces" ];
          modules-right = [ "pulseaudio" "tray" "clock" ];

          "custom/logo" = {
            format = "";
            tooltip = false;
          };

          "hyprland/workspaces" = {
            disable-scroll = true;
            persistent_workspaces = {
              "1" = [ ];
              "2" = [ ];
              "3" = [ ];
              "4" = [ ];
            };
            disable-click = true;
          };

          pulseaudio = {
            format = " {icon} ";
            format-muted = "";
            format-icons = [ "" "󰖀" "󰕾" ];
            tooltip = true;
            tooltip-format = "{volume}%";
          };

          clock = {
            format = ''{:%H:%M}'';
            format-alt = ''{:%d.%m.%Y}'';
            tooltip-format = ''<tt>{calendar}</tt>'';
            calendar = {
              mode = "month";
              mode-mon-col = 3;
              weeks-pos = "right";
              on-scroll = 1;
              format = {
                months = "<span color='#bac2de'><b>{}</b></span>";
                days = "<span color='#cdd6f4'><b>{}</b></span>";
                weeks = "<span color='#f9e2af'><b>W{}</b></span>";
                weekdays = "<span color='#a6adc8'><b>{}</b></span>";
                today = "<span color='#f38ba8'><b><u>{}</u></b></span>";
              };
            };
          };

          tray = {
            icon-size = 21;
            spacing = 10;
          };
        };
      };
    };

    xdg.configFile."waybar/mocha.css".source = ./mocha.css;
    xdg.configFile."waybar/style.css".source = ./style.css;
  };
}
