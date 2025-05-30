{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.apps.hydrus;
in
{
  options.plusultra.apps.hydrus = with types; {
    enable = mkBoolOpt false "Whether or not to enable hydrus.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      hydrus
    ];

    xdg.desktopEntries.hydrus-client = {
      name = "Hydrus Client";
      exec = "${pkgs.hydrus}/bin/hydrus-client -d /home/${config.plusultra.user.name}/hydrus";
      icon = "hydrus-client";
      comment = "Hydrus Client - A personal booru application";
    };

    home.persistence."/hydrus" = {
      removePrefixDirectory = false;
      allowOther = true;
      directories = [
        "hydrus"
      ];
    };
  };
}
