{ lib, ... }:
with lib.plusultra; {
  plusultra = {
    suites = {
      common = enabled;
    };

    desktop.yabai = enabled;
  };

  environment.systemPath = [
    "/opt/homebrew/bin"
  ];

  system.stateVersion = 4;
}
