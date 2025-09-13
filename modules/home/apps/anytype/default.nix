{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.apps.anytype;
in
{
  options.plusultra.apps.anytype = with types; {
    enable = mkBoolOpt false "Whether or not to enable Anytype.";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.anytype
    ];

    plusultra.user.impermanence.directories = [
      ".config/anytype"
    ];
  };
}