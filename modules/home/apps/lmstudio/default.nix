{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.apps.lmstudio;
in
{
  options.plusultra.apps.lmstudio = with types; {
    enable = mkBoolOpt false "Whether or not to enable LM Studio.";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.lmstudio
    ];

    plusultra.user.impermanence.directories = [
      ".lmstudio"
      ".cache/lm-studio"
      ".config/LM Studio"
    ];
  };
}
