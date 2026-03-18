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
      (pkgs.writeShellScriptBin "pi" ''
        export SYNTHETIC_API_KEY=$(cat ${config.age.secrets.synthetic-api.path})
        export EXA_API_KEY=$(cat ${config.age.secrets.exa-api-key.path})
        export ZAI_API_KEY=$(cat ${config.age.secrets.zai.path})
        export OPENROUTER_API_KEY=$(cat ${config.age.secrets.openrouter-api-key.path})
        export OLLAMA_API_KEY=$(cat ${config.age.secrets.ollama-api-key.path})
        exec ${llm-agents.pi}/bin/pi "$@"
      '')
      llm-agents.agent-browser
      pkgs.uv
      pkgs.nodejs
    ];

    plusultra.user.agenix = {
      enable = true;
      enabledSecrets = [
        "synthetic-api.age"
        "exa-api-key.age"
        "zai.age"
        "openrouter-api-key.age"
        "ollama-api-key.age"
      ];
      enableAll = false;
    };

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
