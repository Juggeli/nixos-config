{ lib, config, ... }:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.desktop.yabai;
in
{
  options.plusultra.desktop.yabai = {
    enable = mkBoolOpt false "Whether to enable yabai";
    enable-scripting-addition = mkBoolOpt true "Whether to enable the scripting addition for Yabai. (Requires SIP to be disabled)";
  };

  config = mkIf cfg.enable {
    services.yabai = {
      enable = true;
      enableScriptingAddition = cfg.enable-scripting-addition;

      config = {
        layout = "bsp";

        auto_balance = "off";
        debug_output = "on";

        top_padding = 0;
        right_padding = 0;
        left_padding = 0;
        bottom_padding = 0;

        window_gap = 0;
        window_topmost = "on";
        window_shadow = "float";
        window_border = "on";
        window_border_width = 3;
        window_border_radius = 0;
        window_border_blur = "off";
        window_border_hidpi = "on";
        insert_feedback_color = "0xffb48ead";
        normal_window_border_color = "0xff2e3440";
        active_window_border_color = "0xff5e81ac";

        focus_follows_mouse = "autoraise";

        external_bar = "all:${builtins.toString config.services.spacebar.config.height}:0";

        # mouse_modifier = "alt";
        mouse_modifier = "cmd";
        mouse_action1 = "move";
        mouse_action2 = "resize";
      };

      extraConfig = ''
        yabai -m rule --add app="Finder" manage=off
        yabai -m rule --add app="System Settings" manage=off
        yabai -m rule --add app="App Store" manage=off
        yabai -m rule --add app="Activity Monitor" manage=off
        yabai -m rule --add app="Calculator" manage=off
        yabai -m rule --add app="Dictionary" manage=off
        yabai -m rule --add app="mpv" manage=off
        yabai -m rule --add app="Software Update" manage=off
        yabai -m rule --add app="System Information" manage=off
        yabai -m rule --add app="Raycast" manage=off
        yabai -m rule --add app="1Password" manage=off
        yabai -m rule --add app="^Digital Colou?r Meter$" sticky=on

        # Spaces
        yabai -m space 1 --label slack
        yabai -m space 2 --label browser
        yabai -m space 3 --label term
        yabai -m space 4 --label git
        yabai -m space 5 --label android
        yabai -m space 6 --label ios

        # Assign to spaces
        yabai -m rule --add app="Slack" space=slack
        yabai -m rule --add app="Firefox" space=browser
        yabai -m rule --add app="kitty" space=term
        yabai -m rule --add app="GitKraken" space=git
        yabai -m rule --add app="Android Studio" space=android
        yabai -m rule --add app="XCode" space=ios
      '';
    };
  };
}
