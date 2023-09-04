inputs@{ options, config, lib, pkgs, ... }:

with lib;
with lib.internal;
let
  cfg = config.plusultra.apps.crypto;
in
{
  options.plusultra.apps.crypto = with types; {
    enable = mkBoolOpt false "Whether or not to enable crypto apps.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      ledger-live-desktop
      ledger-udev-rules
      monero-gui
    ];

    services.udev.extraRules = ''
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0666", TAG+="uaccess", TAG+="udev-acl"
    '';
  };
}

