{ lib, ... }:
with lib.plusultra;
{
  plusultra = {
    roles.darwin-common = enabled;
  };

  system.stateVersion = 6;
}
