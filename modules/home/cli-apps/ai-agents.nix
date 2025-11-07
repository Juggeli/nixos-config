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
      gemini-cli
      opencode
    ];
    plusultra.user.impermanence = {
      directories = [
        ".cache/opencode"
        ".local/share/uv"
        ".cache/uv"
        ".codex"
        ".config/opencode"
        ".gemini"
        ".local/share/opencode"
        ".local/state/opencode"
      ];
    };
  };
}
