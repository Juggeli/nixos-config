{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.cli-apps.claude-code;
in
{
  options.plusultra.cli-apps.claude-code = with types; {
    enable = mkBoolOpt false "Whether or not to enable claude-code.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      claude-code
    ];
    plusultra.user.impermanence = {
      directories = [
        ".claude"
      ];
    };
  };
}
