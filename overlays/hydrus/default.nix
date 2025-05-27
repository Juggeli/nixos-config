{ lib, ... }:

final: prev: {
  hydrus = prev.hydrus.overrideAttrs (oldAttrs: {
    doInstallCheck = false;
  });
}