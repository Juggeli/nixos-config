{ lib, ... }:
with lib.plusultra; {
  plusultra = {
    roles.home-common = enabled;
    tools = {
      git = {
        userName = "jukka.alavesa";
        userEmail = "jukka.alavesa@codemate.com";
      };
    };
  };

  home.sessionPath = [
    "$HOME/src/flutter/bin"
    "$HOME/.pub-cache/bin"
    "$HOME/.local/bin"
  ];
}
