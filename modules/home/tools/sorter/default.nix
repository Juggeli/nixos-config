{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.tools.sorter;
in
{
  options.plusultra.tools.sorter = with types; {
    enable = mkBoolOpt false "Whether or not to enable the media sorter tool.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      plusultra.sorter
    ];

    plusultra.user.impermanence = {
      directories = [
        ".config/sorter"
      ];
    };
  };
}

