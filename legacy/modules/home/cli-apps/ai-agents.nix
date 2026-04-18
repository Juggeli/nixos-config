{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.cli-apps.ai-agents;
  llm-agents = inputs.llm-agents.packages.${pkgs.system};
in
{
  options.plusultra.cli-apps.ai-agents = with types; {
    enable = mkBoolOpt false "Whether or not to enable ai-agents.";
  };

  config = mkIf cfg.enable {
    home.packages = [
      llm-agents.codex
      llm-agents.agent-browser
      pkgs.uv
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
