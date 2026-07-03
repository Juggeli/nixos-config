{
  flake.homeModules.pi =
    {
      config,
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      llm-agents = inputs.llm-agents.packages.${pkgs.system};
      homeDir = if pkgs.stdenv.isDarwin then "/Users/juggeli" else "/home/juggeli";
      agentDir = "${homeDir}/.pi/agent";
      rtkOptimizer = pkgs.fetchFromGitHub {
        owner = "MasuRii";
        repo = "pi-rtk-optimizer";
        rev = "v0.9.0";
        hash = "sha256-Cw0oLzVv674vpC3g5oteCNZSkHpfBN+IdnYDbkai4q4=";
      };
      filterTests =
        src:
        lib.cleanSourceWith {
          inherit src;
          filter = path: _type: !(builtins.baseNameOf path == "__tests__");
        };
      extensionsSource = pkgs.runCommand "pi-agent-extensions" { } ''
        mkdir -p $out
        cp -R ${filterTests ../../packages/pi-extensions/packages}/. $out/
        cp -R ${rtkOptimizer}/. $out/pi-rtk-optimizer
      '';
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
            export PI_AGENT_DIR="${agentDir}"
            export EXA_API_KEY=$(cat ${config.age.secrets.exa-api-key.path})
            export ZAI_API_KEY=$(cat ${config.age.secrets.zai-api-key.path})
            export OPENROUTER_API_KEY=$(cat ${config.age.secrets.openrouter-api-key.path})
            exec ${pi}/bin/pi "$@"
          '')
          pkgs.unstable.rtk
          pkgs.nodejs
        ];

        home.file.".pi/agent/extensions" = {
          source = extensionsSource;
          recursive = true;
        };
      };
    };
}
