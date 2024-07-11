{ config, lib, pkgs, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.apps.discord;
in
{
  options.plusultra.apps.discord = with types; {
    enable = mkBoolOpt false "Whether or not to enable Discord.";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.discord
    ];

    plusultra.user.impermanence.directories = [
      ".config/discord"
    ];

    xdg.configFile."discord/settings.json".source = ./settings.json;
  };
}
