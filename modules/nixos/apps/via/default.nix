inputs@{ options, config, lib, pkgs, ... }:

with lib;
with lib.internal;
let
  cfg = config.plusultra.apps.via;
in
{
  options.plusultra.apps.via = with types; {
    enable = mkBoolOpt false "Whether or not to enable via.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      via
    ];

    services.udev.extraRules = ''
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0666", TAG+="uaccess", TAG+="udev-acl"
    '';
  };
}
