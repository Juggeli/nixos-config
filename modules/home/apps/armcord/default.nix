{ config, lib, pkgs, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.apps.armcord;
in
{
  options.plusultra.apps.armcord = with types; {
    enable = mkBoolOpt false "Whether or not to enable armcord.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      armcord
    ];

    plusultra.user.impermanence.directories = [
      ".config/ArmCord"
    ];
  };
}
