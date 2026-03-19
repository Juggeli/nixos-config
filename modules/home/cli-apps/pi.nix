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
  cfg = config.plusultra.cli-apps.pi;
  llm-agents = inputs.llm-agents.packages.${pkgs.system};
  packagesDir = "${config.home.homeDirectory}/.pi/agent/packages";
  filterTests = src: lib.cleanSourceWith {
    inherit src;
    filter = path: _type:
      !(builtins.baseNameOf path == "__tests__");
  };
in
{
  options.plusultra.cli-apps.pi = with types; {
    enable = mkBoolOpt false "Whether or not to enable pi.";
  };

  config = mkIf cfg.enable {
    home.packages = [
      (pkgs.writeShellScriptBin "pi" ''
        export PI_AGENT_DIR="${config.home.homeDirectory}/.pi/agent"
        export SYNTHETIC_API_KEY=$(cat ${config.age.secrets.synthetic-api.path})
        export EXA_API_KEY=$(cat ${config.age.secrets.exa-api-key.path})
        export ZAI_API_KEY=$(cat ${config.age.secrets.zai.path})
        export OPENROUTER_API_KEY=$(cat ${config.age.secrets.openrouter-api-key.path})
        export OLLAMA_API_KEY=$(cat ${config.age.secrets.ollama-api-key.path})
        ${pkgs.nodejs}/bin/node ${packagesDir}/model-sync/sync-models.mjs --if-missing || true
        exec ${llm-agents.pi}/bin/pi -e ${packagesDir}/synthetic "$@"
      '')
      (pkgs.writeShellScriptBin "pi-sync-models" ''
        export PI_AGENT_DIR="${config.home.homeDirectory}/.pi/agent"
        export SYNTHETIC_API_KEY=$(cat ${config.age.secrets.synthetic-api.path})
        export EXA_API_KEY=$(cat ${config.age.secrets.exa-api-key.path})
        export ZAI_API_KEY=$(cat ${config.age.secrets.zai.path})
        export OPENROUTER_API_KEY=$(cat ${config.age.secrets.openrouter-api-key.path})
        export OLLAMA_API_KEY=$(cat ${config.age.secrets.ollama-api-key.path})
        exec ${pkgs.nodejs}/bin/node ${packagesDir}/model-sync/sync-models.mjs "$@"
      '')
      pkgs.nodejs
    ];

    home.file.".pi/agent/packages/model-sync" = {
      source = filterTests ../../../packages/pi-extensions/packages/model-sync;
      recursive = true;
    };

    home.file.".pi/agent/packages/synthetic" = {
      source = filterTests ../../../packages/pi-extensions/packages/synthetic;
      recursive = true;
    };

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
        ".pi"
      ];
    };
  };
}
