{
  flake.nixosModules.home-pi =
    {
      config,
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      llm-agents = inputs.llm-agents.packages.${pkgs.system};
      extensionsDir = "/home/juggeli/.pi/agent/extensions";
      filterTests =
        src:
        lib.cleanSourceWith {
          inherit src;
          filter = path: _type: !(builtins.baseNameOf path == "__tests__");
        };
    in
    {
      home-manager.users.juggeli = {
        home.packages = [
          (pkgs.writeShellScriptBin "pi" ''
            export PI_AGENT_DIR="/home/juggeli/.pi/agent"
            export EXA_API_KEY=$(cat ${config.age.secrets.exa-api-key.path})
            export ZAI_API_KEY=$(cat ${config.age.secrets.zai-api-key.path})
            export OPENROUTER_API_KEY=$(cat ${config.age.secrets.openrouter-api-key.path})
            export OLLAMA_API_KEY=$(cat ${config.age.secrets.ollama-api-key.path})
            ${pkgs.nodejs}/bin/node ${extensionsDir}/model-sync/sync-models.mjs --if-missing || true
            exec ${llm-agents.pi}/bin/pi "$@"
          '')
          (pkgs.writeShellScriptBin "pi-sync-models" ''
            export PI_AGENT_DIR="/home/juggeli/.pi/agent"
            export EXA_API_KEY=$(cat ${config.age.secrets.exa-api-key.path})
            export ZAI_API_KEY=$(cat ${config.age.secrets.zai-api-key.path})
            export OPENROUTER_API_KEY=$(cat ${config.age.secrets.openrouter-api-key.path})
            export OLLAMA_API_KEY=$(cat ${config.age.secrets.ollama-api-key.path})
            exec ${pkgs.nodejs}/bin/node ${extensionsDir}/model-sync/sync-models.mjs "$@"
          '')
          pkgs.nodejs
        ];

        home.file.".pi/agent/extensions" = {
          source = filterTests ../../packages/pi-extensions/packages;
          recursive = true;
        };
      };

      environment.persistence."/persist-home" = {
        users.juggeli.directories = [
          ".pi"
        ];
      };
    };
}
