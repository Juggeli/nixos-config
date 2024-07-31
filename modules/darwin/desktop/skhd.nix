{
  lib,
  pkgs,
  config,
  ...
}:

with lib;
with lib.plusultra;
let
  cfg = config.plusultra.desktop.skhd;
in
{
  options.plusultra.desktop.skhd = {
    enable = mkBoolOpt false "Whether to enable skhd";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.jq ];
    services.skhd = {
      enable = true;
      skhdConfig = ''
        # Movement
        shift + cmd - h : yabai -m window --focus west
        shift + cmd - j : yabai -m window --focus south
        shift + cmd - k : yabai -m window --focus north
        shift + cmd - l : yabai -m window --focus east

        # Window Movement
        lctrl + shift + cmd - h : yabai -m window --swap west
        lctrl + shift + cmd - j : yabai -m window --swap south
        lctrl + shift + cmd - k : yabai -m window --swap north
        lctrl + shift + cmd - l : yabai -m window --swap east

        # Window Resize
        lctrl + cmd - h : yabai -m window --resize left:-50:0; \
                          yabai -m window --resize right:-50:0
        lctrl + cmd - j : yabai -m window --resize bottom:0:50; \
                          yabai -m window --resize top:0:50
        lctrl + cmd - k : yabai -m window --resize top:0:-50; \
                          yabai -m window --resize bottom:0:-50
        lctrl + cmd - l : yabai -m window --resize right:50:0; \
                          yabai -m window --resize left:50:0

        lctrl + alt - h : yabai -m window --resize left:-10:0; \
                    yabai -m window --resize right:-10:0
        lctrl + alt - j : yabai -m window --resize bottom:0:10; \
                    yabai -m window --resize top:0:10
        lctrl + alt - k : yabai -m window --resize top:0:-10; \
                    yabai -m window --resize bottom:0:-10
        lctrl + alt - l : yabai -m window --resize right:10:0; \
                          yabai -m window --resize left:10:0

        lctrl + cmd - e : yabai -m space --balance

        # Move Window To Space
        lctrl + shift + cmd - m : yabai -m window --space last; yabai -m space --focus last
        lctrl + shift + cmd - p : yabai -m window --space prev; yabai -m space --focus prev
        lctrl + shift + cmd - n : yabai -m window --space next; yabai -m space --focus next
        lctrl + shift + cmd - 1 : yabai -m window --space 1; yabai -m space --focus 1
        lctrl + shift + cmd - 2 : yabai -m window --space 2; yabai -m space --focus 2
        lctrl + shift + cmd - 3 : yabai -m window --space 3; yabai -m space --focus 3
        lctrl + shift + cmd - 4 : yabai -m window --space 4; yabai -m space --focus 4

        # Focus Space
        hyper - 1 : yabai -m space --focus 1
        hyper - 2 : yabai -m space --focus 2
        hyper - 3 : yabai -m space --focus 3
        hyper - 4 : yabai -m space --focus 4
        hyper - 5 : yabai -m space --focus 5
        hyper - 6 : yabai -m space --focus 6
        hyper - 7 : yabai -m space --focus 7
        hyper - 8 : yabai -m space --focus 8

        # Floating Windows
        shift + cmd - space : yabai -m window --toggle float

        # Fix balance between kitty and ios simulator
        cmd + shift - f : yabai -m window --resize right:411:0

        # T for terminal
        hyper - t : yabai -m window --focus "$(yabai -m query --windows | jq 'map(select(.app == "kitty")) | .[0].id')" || (yabai -m signal --add event="window_created" label="kitty_label" app="^kitty$" action="yabai -m window \$YABAI_WINDOW_ID --focus && yabai -m signal --remove kitty_label") && open -ga ~/Applications/Home\ Manager\ Apps/kitty.app

        # B for browser
        hyper - b : export MOZ_DISABLE_SAFE_MODE_KEY=1; yabai -m window --focus "$(yabai -m query --windows | jq 'map(select(.app == "Firefox")) | .[0].id')" || (yabai -m signal --add event="window_created" label="firefox_label" app="^Firefox$" action="yabai -m window \$YABAI_WINDOW_ID --focus && yabai -m signal --remove firefox_label") && open -ga /Applications/Firefox.app

        # C for chat
        hyper - c : yabai -m window --focus "$(yabai -m query --windows | jq 'map(select(.app == "Slack")) | .[0].id')" || (yabai -m signal --add event="window_created" label="slack_label" app="^Slack$" action="yabai -m window \$YABAI_WINDOW_ID --focus && yabai -m signal --remove slack_label") && open -ga /Applications/Slack.app

        # Fullscreen
        alt - f : yabai -m window --toggle zoom-fullscreen
        shift + alt - f : yabai -m window --toggle native-fullscreen

        # Restart Yabai
        shift + lctrl + alt - r : \
          /usr/bin/env osascript <<< \
            "display notification \"Restarting Yabai\" with title \"Yabai\""; \
          launchctl kickstart -k "gui/$UID/org.nixos.yabai"

        # Restart Spacebar
        shift + lctrl + alt - s : \
          /usr/bin/env osascript <<< \
            "display notification \"Restarting Spacebar\" with title \"Spacebar\""; \
          launchctl kickstart -k "gui/$UID/org.nixos.spacebar"
      '';
    };
  };
}
