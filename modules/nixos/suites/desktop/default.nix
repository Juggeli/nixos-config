{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.suites.desktop;
in {
  options.plusultra.suites.desktop = with types; {
    enable =
      mkBoolOpt false "Whether or not to enable common desktop configuration.";
  };

  config = mkIf cfg.enable {
    plusultra = {
      apps = {
        _1password = enabled;
      };
      desktop = {
        sway = enabled;
        hyprland = enabled;
      };

      services = {
        avahi = enabled;
        printing = enabled;
        tailscale = enabled;
      };
    };
  };
}
