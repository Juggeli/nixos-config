{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.apps.gaming;
in
{
  options.plusultra.apps.gaming = with types; {
    enable = mkBoolOpt false "Whether or not to enable gaming.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      heroic
    ];
    programs.steam.enable = true;

    environment.persistence."/persist-home" = {
      users."${config.plusultra.user.name}".directories = [
        ".local/share/Steam"
        ".steam"
        ".config/heroic"
      ];
    };
  };
}
