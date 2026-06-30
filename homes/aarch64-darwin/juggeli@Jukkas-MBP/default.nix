{ lib, ... }:
with lib.plusultra;
{
  plusultra = {
    roles.home-common = enabled;
    apps.ghostty.fontSize = 16;
    tools = {
      git = {
        userName = "jukka.alavesa";
        userEmail = "jukka.alavesa@codemate.com";
      };
    };
  };

  home.sessionVariables = {
    ANDROID_HOME = "$HOME/Library/Android/sdk";
  };

  home.sessionPath = [
    "/opt/homebrew/bin"
    "$HOME/src/flutter/bin"
    "$HOME/.pub-cache/bin"
    "$HOME/.local/bin"
    "$HOME/Library/Android/sdk/platform-tools"
    "$HOME/Library/Android/sdk/emulator"
    "/Applications/microchip/xc8/v2.50/bin"
    "/Applications/microchip/mplabx/6.30/MPLAB X IDE v6.30.app/Contents/Resources/mplab_ide/bin"
  ];
}
