{ options, config, pkgs, lib, ... }:

with lib;
with lib.internal;
{
  plusultra.home.extraOptions.programs.nushell = {
    enable = true;
    package = pkgs.nushell;
    envFile.source = ./nu/env.nu;
    configFile.source = ./nu/config.nu;
  };
}


