{ options, config, lib, pkgs, inputs, ... }:

with lib;
with lib.internal;
let cfg = config.plusultra.desktop.addons.waybar;
in
{
  options.plusultra.desktop.addons.waybar = with types; {
    enable =
      mkBoolOpt false "Whether to enable Waybar in the desktop environment.";
  };

  config = mkIf cfg.enable {
    plusultra.home.extraOptions.programs.waybar = {
      enable = true;
      settings = {
        mainBar = {
          layer = "top";
          position = "bottom";
          margin-top = 0;
          margin-left = 1200;
          margin-right = 1200;
          margin-bottom = 6;
          modules-left = [ "wlr/workspaces" ];
          modules-center = [ "sway/window" ];
          modules-right = [ "pulseaudio" "network" "clock" "tray" ];

          "wlr/workspaces" = {
            disable-scroll = true;
            sort-by-name = true;
            format = "{icon}";
            format-icons = { default = ""; };
          };

          pulseaudio = {
            format = " {icon} ";
            format-muted = "ﱝ";
            format-icons = [ "奄" "奔" "墳" ];
            tooltip = true;
            tooltip-format = "{volume}%";
          };

          network = {
            format-wifi = " ";
            format-disconnected = "睊";
            format-ethernet = " ";
            tooltip = true;
            tooltip-format = "{signalStrength}%";
          };

          "custom/power" = {
            tooltip = false;
            on-click = "powermenu";
            format = "襤";
          };

          clock = {
            tooltip-format = ''<big>{:%Y %B}</big>
              <tt><small>{calendar}</small></tt>'';
            format-alt = ''{:%d.%m.%Y}'';
            format = ''{:%H:%M}'';
          };

          tray = {
            icon-size = 21;
            spacing = 10;
          };
        };
      };
    };

    plusultra.home.configFile."waybar/mocha.css".source = ./mocha.css;
    plusultra.home.configFile."waybar/style.css".source = ./style.css;
  };
}
