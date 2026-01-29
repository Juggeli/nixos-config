{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.cli-apps.opencode;
in
{
  options.plusultra.cli-apps.opencode = with types; {
    enable = mkBoolOpt false "Whether or not to enable opencode.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      opencode
      nodejs
    ];

    plusultra.user.impermanence = {
      directories = [
        ".cache/opencode"
        ".config/opencode"
        ".local/share/opencode"
        ".local/state/opencode"
      ];
    };
  };
}
