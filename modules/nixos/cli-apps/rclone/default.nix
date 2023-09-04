inputs@{ options, config, lib, pkgs, ... }:

with lib;
with lib.internal;
let
  cfg = config.plusultra.cli-apps.rclone;
in
{
  options.plusultra.cli-apps.rclone = with types; {
    enable = mkBoolOpt false "Whether or not to enable rclone.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      rclone
    ];
  };
}

