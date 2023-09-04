inputs@{ options, config, lib, pkgs, ... }:

with lib;
with lib.internal;
let
  cfg = config.plusultra.cli-apps.sshfs;
in
{
  options.plusultra.cli-apps.sshfs = with types; {
    enable = mkBoolOpt false "Whether or not to enable sshfs.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      sshfs
    ];
  };
}


