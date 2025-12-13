{ lib, inputs, ... }:

final: prev: {
  hydrus =
    inputs.unstable.legacyPackages.${final.stdenv.hostPlatform.system}.hydrus.overrideAttrs
      (oldAttrs: {
        doCheck = false;
        doInstallCheck = false;
        propagatedBuildInputs = builtins.filter (
          dep: dep != final.python3Packages.psd-tools
        ) oldAttrs.propagatedBuildInputs;
      });
}
