{ lib, ... }:
with lib.plusultra;
{
  plusultra = {
    roles.home-common = enabled;
    cli-apps.syncthing = enabled;
  };

  home.sessionPath = [
  ];
}
