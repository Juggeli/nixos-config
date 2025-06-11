{ lib, ... }:
with lib.plusultra;
{
  plusultra = {
    roles.home-common = enabled;
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
  ];
}
