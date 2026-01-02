{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.cli-apps.ai-agents;
in
{
  options.plusultra.cli-apps.ai-agents = with types; {
    enable = mkBoolOpt false "Whether or not to enable ai-agents.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      codex
      uv
      nodejs
    ];
    plusultra.user.impermanence = {
      directories = [
        ".local/share/uv"
        ".cache/uv"
        ".codex"
        ".gemini"
      ];
    };
  };
}
