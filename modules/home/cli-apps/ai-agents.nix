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
      claude-code
      codex
      aider-chat
      uv
      plusultra.task-master-ai
      nodejs
      plusultra.gemini-cli
      plusultra.opencode
    ];
    plusultra.user.impermanence = {
      directories = [
        ".claude"
        ".local/share/uv"
        ".cache/uv"
        ".aider"
        ".codex"
        ".config/claude"
        ".gemini"
        ".local/share/opencode"
        ".local/state/opencode"
      ];
      files = [
        ".claude.json"
      ];
    };
  };
}
