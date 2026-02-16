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
  pi-mono = inputs.pi-mono.packages.${pkgs.system};
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
        exec ${pi-mono.pi}/bin/pi "$@"
      '')
      llm-agents.agent-browser
      pkgs.uv
      pkgs.nodejs
    ];

    plusultra.user.agenix = {
      enable = true;
      enabledSecrets = [ "synthetic-api.age" "exa-api-key.age" "zai.age" "openrouter-api-key.age" ];
      enableAll = false;
    };

    home.file.".pi/agent/extensions" = {
      source = "${pi-mono.pi-extensions}";
      recursive = true;
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
