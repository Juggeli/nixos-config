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
      pi = llm-agents.pi.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          substituteInPlace $out/lib/node_modules/@earendil-works/pi-coding-agent/dist/core/tools/read.js \
            --replace-fail \
              'text.setText(formatReadResult(context.args, result, options, theme, context.showImages, context.cwd, context.isError));' \
              'const output = getTextOutput(result, context.showImages);
            const displayOutput = output.replace(/\n\n\[(?:\d+ more lines in file|Showing lines ).*$/s, "");
            const lineCount = trimTrailingEmptyLines(displayOutput.split("\n")).length;
            const readLineCount = result.details?.truncation?.outputLines ?? lineCount;
            text.setText(theme.fg("muted", `\n[Read ''${readLineCount} line''${readLineCount === 1 ? "" : "s"}]`));'
        '';
      });
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
            exec ${pi}/bin/pi "$@"
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
