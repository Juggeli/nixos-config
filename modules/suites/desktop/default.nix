{ options, config, lib, pkgs, ... }:

with lib;
with lib.internal;
let
  cfg = config.plusultra.suites.desktop;
in
{
  options.plusultra.suites.desktop = with types; {
    enable =
      mkBoolOpt false "Whether or not to enable common desktop configuration.";
  };

  config = mkIf cfg.enable {
    plusultra = {
      desktop = {
        sway = enabled;
        hyprland = enabled;
      };

      services = {
        avahi = enabled;
        printing = enabled;
        tailscale = enabled;
      };

      cli-apps = {
        imv = enabled;
      };

      apps = {
        _1password = enabled;
        firefox = enabled;
        chrome = enabled;
        kitty = enabled;
        mpv = enabled;
        via = enabled;
        pdf = enabled;
      };
    };
  };
}
