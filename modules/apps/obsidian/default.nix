{ options, config, lib, pkgs, ... }:

with lib;
with lib.internal;
let
  cfg = config.plusultra.apps.obsidian;
in
{
  options.plusultra.apps.obsidian = with types; {
    enable = mkBoolOpt false "Whether or not to enable obsidian.";
  };

  config = mkIf cfg.enable {
    nixpkgs.config.permittedInsecurePackages = [
      "electron-21.4.0"
    ];

    environment.systemPackages = with pkgs; [
      obsidian
    ];
  };
}

