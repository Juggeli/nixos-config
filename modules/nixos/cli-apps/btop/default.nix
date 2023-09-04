inputs@{ options, config, lib, pkgs, ... }:

with lib;
with lib.internal;
let
  cfg = config.plusultra.cli-apps.btop;
in
{
  options.plusultra.cli-apps.btop = with types; {
    enable = mkBoolOpt false "Whether or not to enable btop.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      btop
    ];
    plusultra.home.configFile = {
      "btop/btop.conf".source = ./btop.conf;
      "btop/themes/catppuccin.theme".source = ./catppuccin.theme;
    };
  };
}

