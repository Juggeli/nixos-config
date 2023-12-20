{ lib, config, ... }:
let
  cfg = config.plusultra.desktop.yabai;

  inherit (lib) types mkEnableOption mkIf;
  inherit (lib.plusultra) mkOpt enabled;
in
{
  options.plusultra.desktop.yabai = {
    enable = mkEnableOption "Yabai";
    enable-scripting-addition = mkOpt types.bool true "Whether to enable the scripting addition for Yabai. (Requires SIP to be disabled)";
  };

  config = mkIf cfg.enable {
    plusultra.desktop.addons = {
      skhd = enabled;
      spacebar = enabled;
    };

    services.yabai = {
      enable = true;
      enableScriptingAddition = cfg.enable-scripting-addition;

      config = {
        layout = "bsp";

        auto_balance = "on";

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
        yabai -m rule --add label="Finder" app="^Finder$" title="(Co(py|nnect)|Move|Info|Pref)" manage=off
        yabai -m rule --add label="Safari" app="^Safari$" title="^(General|(Tab|Password|Website|Extension)s|AutoFill|Se(arch|curity)|Privacy|Advance)$" manage=off
        yabai -m rule --add label="System Preferences" app="^System Preferences$" title=".*" manage=off
        yabai -m rule --add label="App Store" app="^App Store$" manage=off
        yabai -m rule --add label="Activity Monitor" app="^Activity Monitor$" manage=off
        yabai -m rule --add label="Calculator" app="^Calculator$" manage=off
        yabai -m rule --add label="Dictionary" app="^Dictionary$" manage=off
        yabai -m rule --add label="mpv" app="^mpv$" manage=off
        yabai -m rule --add label="Software Update" title="Software Update" manage=off
        yabai -m rule --add label="About This Mac" app="System Information" title="About This Mac" manage=off
      '';
    };
  };
}
