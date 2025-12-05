{ lib, inputs, ... }:

final: prev: {
  hydrus =
    inputs.unstable.legacyPackages.${final.stdenv.hostPlatform.system}.hydrus.overrideAttrs
      (oldAttrs: {
        doInstallCheck = false;
      });
}
