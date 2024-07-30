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
        layout = "stack";

        auto_balance = "off";
        debug_output = "on";

        top_padding = 0;
        right_padding = 0;
        left_padding = 0;
        bottom_padding = 0;

        window_gap = 0;
        window_shadow = "off";
        window_border = "off";

        focus_follows_mouse = "off";

        external_bar = "all:${builtins.toString config.services.spacebar.config.height}:0";

        mouse_modifier = "cmd";
        mouse_action1 = "move";
        mouse_action2 = "resize";
      };

      extraConfig = ''
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

        yabai -m signal --add event=window_focused action="keyboardSwitcher select 'U.S.'" app="kitty"
        yabai -m signal --add event=window_focused action="keyboardSwitcher select 'U.S.'" app="XCode"
        yabai -m signal --add event=window_focused action="keyboardSwitcher select 'U.S.'" app="Android Studio"
        yabai -m signal --add event=window_focused action="keyboardSwitcher select 'Finnish'" app="Slack"
        yabai -m signal --add event=window_focused action="keyboardSwitcher select 'Finnish'" app="Firefox"
      '';
    };
  };
}
