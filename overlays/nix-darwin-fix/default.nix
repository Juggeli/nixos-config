{ ... }:

final: prev:
if prev.stdenv.isDarwin then {
  nix = prev.nix.overrideAttrs {
    doCheck = false;
    doInstallCheck = false;
  };
}
else { }
