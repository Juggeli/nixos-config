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

    plusultra.home.configFile."hypr/hyprlock.conf".text = ''
      general {
        grace = 10
        hide_cursor = true
      }

      background {
        path = screenshot
        blur_passes = 2
      }

      input-field {
        size = 220, 60
        position = 0, -80
        monitor =
        dots_center = true
        fade_on_empty = false
        font_color = rgb(CDD6F4)
        inner_color = rgb(1E1E2E)
        outer_color = rgb(89B4FA)
        outline_thickness = 5
        placeholder_text = Password...
        shadow_passes = 2
      }
    '';
  };
}
