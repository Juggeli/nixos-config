inputs@{ options, config, lib, pkgs, ... }:

with lib;
with lib.internal;
let
  cfg = config.plusultra.cli-apps.vifm;
in
{
  options.plusultra.cli-apps.vifm = with types; {
    enable = mkBoolOpt false "Whether or not to enable vifm.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      vifm
    ];

    plusultra.home = {
      configFile = {
        "vifm/vifmrc".source = ./vifmrc;
        "vifm/colors/material.vifm".source = ./material.vifm;
      };
    };
  };
}