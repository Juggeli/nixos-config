{ lib, inputs, ... }:

final: prev: {
  hydrus = inputs.unstable.legacyPackages.${final.system}.hydrus.overrideAttrs (oldAttrs: {
    doInstallCheck = false;
  });
}
