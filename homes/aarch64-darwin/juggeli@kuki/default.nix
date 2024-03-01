{ lib, ... }:
with lib.plusultra; {
  plusultra = {
    roles.home-common = enabled;
  };

  home.sessionPath = [
  ];
}
