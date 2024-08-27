{ lib, ... }:
with lib.plusultra;
{
  plusultra = {
    roles.darwin-common = enabled;
  };

  environment.systemPath = [
    "/opt/homebrew/bin"
  ];

  system.stateVersion = 4;
}
