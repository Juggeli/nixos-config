{ config, lib, pkgs, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.cli-apps.sshfs;
in
{
  options.plusultra.cli-apps.sshfs = with types; {
    enable = mkBoolOpt false "Whether or not to enable sshfs.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      sshfs
    ];
  };
}
