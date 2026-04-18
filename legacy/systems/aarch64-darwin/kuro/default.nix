{ lib, ... }:
with lib.plusultra;
{
  plusultra = {
    roles.darwin-common = enabled;
    services.tailscale = enabled;
  };

  system.stateVersion = 6;
}
