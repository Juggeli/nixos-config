inputs @ {
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.cli-apps.rclone;
in {
  options.plusultra.cli-apps.rclone = with types; {
    enable = mkBoolOpt false "Whether or not to enable rclone.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      rclone
    ];
  };
}
