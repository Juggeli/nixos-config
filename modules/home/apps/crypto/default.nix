{ config, lib, pkgs, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.apps.crypto;
in
{
  options.plusultra.apps.crypto = with types; {
    enable = mkBoolOpt false "Whether or not to enable crypto apps.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      ledger-live-desktop
      ledger-udev-rules
      monero-gui
    ];
  };
}
