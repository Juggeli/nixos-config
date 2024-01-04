{ config, lib, pkgs, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.cli-apps.vifm;
in
{
  options.plusultra.cli-apps.vifm = with types; {
    enable = mkBoolOpt false "Whether or not to enable vifm.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      vifm
    ];

    xdg.configFile = {
      "vifm/vifmrc".source = ./vifmrc;
      "vifm/icons.vifm".source = ./icons.vifm;
      "vifm/colors/catppuccin.vifm".source = ./catppuccin.vifm;
    };
  };
}
