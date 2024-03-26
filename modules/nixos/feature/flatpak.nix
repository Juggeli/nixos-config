{ config, lib, pkgs, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.feature.flatpak;
in
{
  options.plusultra.feature.flatpak = with types; {
    enable = mkBoolOpt false "Whether or not to enable flatpak.";
  };

  config = mkIf cfg.enable {
    services.flatpak.enable = true;
    environment.systemPackages = with pkgs; [
      gnome.gnome-software
    ];

    plusultra.filesystem.impermanence.directories = [
      "/var/lib/flatpak"
    ];
  };
}
