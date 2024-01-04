{ lib, host ? null, ... }:

let
  inherit (lib) types;
  inherit (lib.plusultra) mkOpt;
in
{
  options.plusultra.host = {
    name = mkOpt (types.nullOr types.str) host "The host name.";
  };
}

