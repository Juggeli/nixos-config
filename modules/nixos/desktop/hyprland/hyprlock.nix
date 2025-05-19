{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.desktop.hyprland.hyprlock;
in
{
  options.plusultra.desktop.hyprland.hyprlock = with types; {
    enable = mkBoolOpt false "Whether or not to enable hyprlock.";
  };

  config = mkIf cfg.enable {
    security.pam.services.hyprlock = { };

    environment.systemPackages = with pkgs; [
      hyprlock
    ];

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
  };
}

